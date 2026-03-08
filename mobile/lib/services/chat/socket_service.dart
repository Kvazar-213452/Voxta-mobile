import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import '../../models/storage_user.dart';
import '../../models/interface/user.dart';
import '../../models/interface/chat_models.dart';
import '../../config.dart';
import 'utils.dart';
import '../../utils/crypto/crypto_auto.dart';
import '../../models/storage_chat_key.dart';
import '../../utils/crypto/crypto_msg.dart';
import "../../models/storage_settings.dart";

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  String _currentChatId = "";
  
  Function(Map<String, dynamic>)? _onMessageReceived;
  Function()? _onReloadChatContent;
  Function(List<ChatItem>)? _onChatsReceived;
  Function(Map<String, dynamic>)? _onChatContentReceived;

  bool get isConnected => _socket?.connected ?? false;
  IO.Socket? get socket => _socket;

  void connectSocket(
    UserModel user,
    String token,
    Function(Map<String, dynamic>) onMessageReceived,
    Function() onReloadChatContent, {
    Function(List<ChatItem>)? onChatsReceived,
    Function(Map<String, dynamic>)? onChatContentReceived,
  }) {
    _registerCallbacks(
      onMessageReceived,
      onReloadChatContent,
      onChatsReceived,
      onChatContentReceived,
    );
    
    saveUserStorage(user);
    _initializeSocket(token, user);
  }

  void _registerCallbacks(
    Function(Map<String, dynamic>) onMessageReceived,
    Function() onReloadChatContent,
    Function(List<ChatItem>)? onChatsReceived,
    Function(Map<String, dynamic>)? onChatContentReceived,
  ) {
    _onMessageReceived = onMessageReceived;
    _onReloadChatContent = onReloadChatContent;
    _onChatsReceived = onChatsReceived;
    _onChatContentReceived = onChatContentReceived;
  }

  void _initializeSocket(String token, UserModel user) {
    try {
      _socket = IO.io(
        Config.URL_SERVICES_CHAT,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setTimeout(10000)
            .build(),
      );

      _setupEventListeners(token, user);
      _socket!.connect();
    } catch (e) {
      print('Socket connection error: $e');
    }
  }

  void _setupEventListeners(String token, UserModel user) {
    _socket!.onConnect((_) => _handleConnect(token));
    _socket!.on('send_message_return', (data) => _handleMessageReturn(data, user));
    _socket!.on('del_msg', (_) => _handleDeleteMessage());
    _socket!.on('make_key_pub_chat', (data) => _handleMakePublicKey(data));
    _socket!.on('authenticated', (data) => _handleAuthenticated(data));
    _socket!.on('chats_info', (data) => _handleChatsInfo(data));
    _socket!.on('load_chat_content_return', (data) => _handleChatContentReturn(data, user));
    _socket!.on('create_new_chat', (_) => loadChats());
    _socket!.on('get_info_self', (data) => _handleGetInfoSelf(data));
    _socket!.onDisconnect((reason) => print('Disconnected: $reason'));
  }

  Future<void> _handleConnect(String token) async {
    print('Connected to socket server');
    _socket!.emit('authenticate', await encrypt_auto({'token': token}));
  }

  Future<void> _handleMessageReturn(dynamic data, UserModel user) async {
    try {
      final messageData = _parseMessageData(data);
      if (messageData == null || _currentChatId.isEmpty) {
        print('Invalid message data or missing chat ID');
        return;
      }

      final decryptedMessage = await _decryptIncomingMessage(
        messageData,
        user.id,
        _currentChatId,
      );

      if (decryptedMessage != null) {
        _onMessageReceived?.call(decryptedMessage);
      }
    } catch (e, stackTrace) {
      print('Error handling message: $e\n$stackTrace');
    }
  }

  Map<String, dynamic>? _parseMessageData(dynamic data) {
    if (data is Map && data.containsKey('data')) {
      final innerData = data['data'];
      
      if (innerData is String) {
        return jsonDecode(innerData) as Map<String, dynamic>;
      } else if (innerData is Map) {
        return Map<String, dynamic>.from(innerData);
      }
    } else if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    
    return null;
  }

  Future<Map<String, dynamic>?> _decryptIncomingMessage(
    Map<String, dynamic> messageData,
    String userId,
    String chatId,
  ) async {
    var decrypted = decryptMessageEndToEnd(messageData, userId);
    decrypted = await decryptMessageEndToEndFull(decrypted, chatId);
    return await decryptMessage(decrypted, chatId);
  }

  void _handleDeleteMessage() {
    _onReloadChatContent?.call();
  }

  Future<void> _handleMakePublicKey(dynamic data) async {
    final keys = await ChatKeysDB.generateAndSaveRSAKeys(data["chatId"]);
    
    _socket!.emit('set_pub_key_for_user', {
      'id': data['chatId'],
      'userId': data['userId'],
      'key': keys["public"],
    });
  }

  Future<void> _handleAuthenticated(dynamic data) async {
    final decrypted = await decrypted_auto(data);
    
    if (decrypted["code"] == 1) {
      await loadChats();
    }
  }

  Future<void> _handleChatsInfo(dynamic data) async {
    final decrypted = await decrypted_auto(data);
    
    if (decrypted["code"] == 1) {
      final parsedChats = _parseChatsFromServer(decrypted["chats"]);
      _onChatsReceived?.call(parsedChats);
    }
  }

  Future<void> _handleChatContentReturn(dynamic data, UserModel user) async {
    var decrypted = await decrypted_auto(data);
    final messages = (decrypted["messages"] as List?) ?? [];

    if (messages.isNotEmpty) {
      decrypted = await _decryptChatMessages(decrypted, user.id);
    }

    _currentChatId = decrypted["chatId"];
    _onChatContentReceived?.call(decrypted as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> _decryptChatMessages(
    Map<String, dynamic> data,
    String userId,
  ) async {
    if (data["typeChat"] == "secret") {
      return await decryptMessages(data);
    } else {
      var decrypted = await decryptMessagesEndToEnd(data, userId);
      decrypted = await decryptMessagesEndToEndFull(decrypted, data["chatId"]);
      return await decryptMessages(decrypted);
    }
  }

  Future<void> _handleGetInfoSelf(dynamic data) async {
    final decrypted = await decrypted_auto(data);

    if (decrypted['type'] == "load_chats") {
      final userMap = decrypted['user'];
      
      if (userMap != null && userMap is Map<String, dynamic>) {
        final user = UserModel.fromJson(userMap);
        await saveUserStorage(user);

        _socket!.emit(
          'getInfoChats',
          await encrypt_auto({'chats': user.chats}),
        );
      }
    }
  }

  List<ChatItem> _parseChatsFromServer(Map<String, dynamic> chatsData) {
    final chatsList = <ChatItem>[];

    chatsData.forEach((chatId, chatInfo) {
      try {
        final chatItem = ChatItem(
          id: chatId,
          name: chatInfo['name'] ?? 'Невідомий чат',
          lastMessage: (chatInfo['desc'] ?? '').isNotEmpty 
              ? chatInfo['desc'] 
              : 'Немає повідомлень',
          time: formatTime(chatInfo['createdAt'] ?? ''),
          avatar: chatInfo['avatar'] ?? '',
          type: chatInfo['type'] ?? '',
          owner: chatInfo['owner'] ?? '',
        );

        chatsList.add(chatItem);
      } catch (e) {
        print('Error parsing chat $chatId: $e');
      }
    });

    chatsList.sort((a, b) => b.time.compareTo(a.time));
    return chatsList;
  }

  Future<void> loadChats() async {
    _socket?.emit('get_info_self', await encrypt_auto({'type': 'load_chats'}));
  }

  Future<void> sendMessage(
    Object text,
    String userId,
    String chatId,
    String type,
    String typeMsg,
  ) async {
    if (typeMsg == "file") {
      await _sendFileMessage(text, userId, chatId, type);
    } else {
      await _sendTextMessage(text, userId, chatId, type, typeMsg);
    }
  }

  Future<void> _sendTextMessage(
    Object text,
    String userId,
    String chatId,
    String type,
    String typeMsg,
  ) async {
    final settings = await SettingsDB.getSettings();
    final info = await ChatKeysDB.getChatInfo(chatId);
    String? keyChat = await ChatKeysDB.getKeyAES(chatId);

    if (info?["isEncrypted"] == false) {
      keyChat = null;
    }

    var content = text;
    if (keyChat != null && keyChat.isNotEmpty) {
      content = encryptText(text.toString(), keyChat);
    }

    final messageData = {
      'message': {
        'content': content,
        if (type != "secret") 'sender': userId,
        'type': typeMsg,
        'time': DateTime.now().toIso8601String(),
      },
      'chatId': chatId,
      'typeChat': type,
    };

    final encrypted = type == "online"
        ? await encryptAutoToUsers(messageData, chatId, encryptionType: settings?.encryptionLevel)
        : messageData;

    print(encrypted);

    _socket?.emit('send_message', await encryptAutoServer(encrypted));
  }

  Future<void> _sendFileMessage(
    Object text,
    String userId,
    String chatId,
    String type,
  ) async {
    final map = text as Map<String, dynamic>;
    final fileName = map["fileName"] as String?;
    final fileSize = map["fileSize"] as int?;
    
    if (fileName == null) {
      print('fileName is missing');
      return;
    }

    final info = await ChatKeysDB.getChatInfo(chatId);
    String? keyChat = await ChatKeysDB.getKeyAES(chatId);

    if (info?["isEncrypted"] == false) {
      keyChat = null;
    }

    String base64Data = map["base64Data"] as String;
    
    if (keyChat != null && keyChat.isNotEmpty) {
      base64Data = encryptText(base64Data, keyChat);
    }

    final uploadedUrl = await uploadLargeFileBase64(base64Data, fileName);
    
    if (uploadedUrl == null) {
      print('Failed to upload file');
      return;
    }

    final messageData = {
      'message': {
        'content': {
          "fileName": fileName,
          "fileSize": fileSize,
          "urlFile": uploadedUrl,
        },
        if (type != "secret") 'sender': userId,
        'type': "longFile",
        'time': DateTime.now().toIso8601String(),
      },
      'chatId': chatId,
      'typeChat': type,
    };

    final encrypted = type == "secret"
        ? await encryptAutoToUsers(messageData, chatId)
        : messageData;

    _socket?.emit('send_message', await encryptAutoServer(encrypted));
  }

  Future<void> loadChatContent(String chatId, String type) async {
    final infoUser = await getUserStorage();

    _socket?.emit(
      'load_chat_content',
      await encrypt_auto({
        'chatId': chatId,
        'type': type,
        'userId': infoUser?.id,
      }),
    );
  }

  Future<void> createChat(
    String name,
    String type,
    String avatar,
    String desc,
  ) async {
    final chatData = {
      'chat': {
        'name': name,
        'description': desc,
        'privacy': type,
        'avatar': avatar,
        'createdAt': DateTime.now().toIso8601String(),
      },
    };

    _socket?.emit('create_chat', await encrypt_auto(chatData));
  }

  Future<void> createTemporaryChat(
    String chatName,
    String privacy,
    String avatarBase64,
    String chatDescription,
    int expirationHours,
    String password,
  ) async {
    final expirationDate = DateTime.now()
        .add(Duration(hours: expirationHours))
        .toIso8601String();

    final chatData = {
      'chat': {
        'name': chatName,
        'privacy': privacy,
        'avatar': avatarBase64,
        'desc': chatDescription,
        'expirationHours': expirationDate,
        'password': password,
        'createdAt': DateTime.now().toIso8601String(),
      },
    };

    _socket?.emit('create_temporary_chat', await encrypt_auto(chatData));
  }

  void disconnectSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentChatId = "";
  }
}

IO.Socket? socket;

void connectSocket(
  UserModel user,
  String token,
  Function(Map<String, dynamic>) onMessageReceived,
  Function() onReloadChatContent, {
  Function(List<ChatItem>)? onChatsReceived,
  Function(Map<String, dynamic>)? onChatContentReceived,
}) {
  SocketService().connectSocket(
    user,
    token,
    onMessageReceived,
    onReloadChatContent,
    onChatsReceived: onChatsReceived,
    onChatContentReceived: onChatContentReceived,
  );
  socket = SocketService().socket;
}

Future<void> loadChats() => SocketService().loadChats();

void sendMessage(
  Object text,
  String userId,
  String chatId,
  String type,
  String typeMsg,
) =>
    SocketService().sendMessage(text, userId, chatId, type, typeMsg);

void loadChatContent(String chatId, String type) =>
    SocketService().loadChatContent(chatId, type);

void createChat(String name, String type, String avatar, String desc) =>
    SocketService().createChat(name, type, avatar, desc);

void createTemporaryChat(
  String chatName,
  String privacy,
  String avatarBase64,
  String chatDescription,
  int expirationHours,
  String password,
) =>
    SocketService().createTemporaryChat(
      chatName,
      privacy,
      avatarBase64,
      chatDescription,
      expirationHours,
      password,
    );

void disconnectSocket() => SocketService().disconnectSocket();

bool get isSocketConnected => SocketService().isConnected;
