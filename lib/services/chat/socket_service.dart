import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../models/storage_user.dart';
import '../../models/offline_chat.dart';
import '../../models/interface/user.dart';
import '../../models/interface/chat_models.dart';
import '../../config.dart';
import 'dart:convert';
import 'utils.dart';
import '../../utils/crypto/crypto_app.dart';
import '../../models/storage_key.dart';
import '../../utils/crypto/utils.dart';
import '../../models/interface/offlne_msg.dart';

IO.Socket? _socket;
Function(Map<String, dynamic>)? _onMessageReceived;
Function(List<ChatItem>)? _onChatsReceived;
Function(Map<String, dynamic>)? _onChatContentReceived;

void connectSocket(
  UserModel user, 
  String token, 
  Function(Map<String, dynamic>) onMessageReceived,
  {Function(List<ChatItem>)? onChatsReceived,
   Function(Map<String, dynamic>)? onChatContentReceived}
) {
  _onMessageReceived = onMessageReceived;
  _onChatsReceived = onChatsReceived;
  _onChatContentReceived = onChatContentReceived;
  saveUserStorage(user);
  
  try {
    _socket = IO.io(Config.URL_SERVICES_CHAT, 
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .setTimeout(10000)
        .build()
    );

    _socket!.onConnect((_) {
      print('Підключено до сокет-серверу');
      _socket!.emit('authenticate', {'token': token});
    });

    _socket!.on('send_message_return', (data) async {
      final keyPair = await getOrCreateKeyPair();

      final jsonResponse = data;
      final decrypted = await decryptServerResponse(jsonResponse, keyPair.privateKey);
      
      data = jsonDecode(decrypted);
      
      _onMessageReceived!(data as Map<String, dynamic>);
    });

    _socket!.on('authenticated', (data) {
      if (data["code"] == 1) {
        loadChats();
      }
    });

    _socket!.on('chats_info', (data) {
      if (data["code"] == 1) {
        print(data["chats"]);
        List<ChatItem> parsedChats = _parseChatsFromServer(data["chats"]);
        
        _onChatsReceived!(parsedChats);
      }
    });

    _socket!.on('load_chat_content_return', (data) async {
      if (data["type"] == "offline") {
        final msg = await ChatDB.getMessagesByChatId(data["chatId"]);

        final Map<String, dynamic> data_send = {
          "messages": msg.map((m) => m.toJson()).toList(),
          "chatId": data["chatId"],
          "participants": data["participants"],
          "type": "offline",
          "code": 1
        };

        print(data_send);

        _onChatContentReceived!(data_send);
      } else {
        _onChatContentReceived!(data as Map<String, dynamic>);
      }
    });

    _socket!.on('create_new_chat', (data) {
      loadChats();
    });
    
    _socket!.on('get_info_self', (data) async {
      if (data['type'] == "load_chats") {
        final userMap = data['user'];
        if (userMap != null && userMap is Map<String, dynamic>) {
          UserModel user = UserModel.fromJson(userMap);
          await saveUserStorage(user);
          _socket!.emit('getInfoChats', {'chats': user.chats});
        } else {
          print("user is null");
        }
      }
    });

    _socket!.onDisconnect((reason) {
      print('Відключено від сервера: $reason');
    });

    _socket!.connect();
  } catch (e) {
    print('Помилка підключення: $e');
  }
}

void loadChats() {
  _socket!.emit('get_info_self', {'type': 'load_chats'});
}

List<ChatItem> _parseChatsFromServer(Map<String, dynamic> chatsData) {
  List<ChatItem> chatsList = [];
  
  chatsData.forEach((chatId, chatInfo) {
    try {
      String name = chatInfo['name'] ?? 'Невідомий чат';
      String avatar = chatInfo['avatar'] ?? '';
      String type = chatInfo['type'] ?? '';
      String desc = chatInfo['desc'] ?? '';
      String createdAt = chatInfo['createdAt'] ?? '';

      String displayAvatar = avatar.isNotEmpty ? avatar : "";
      
      ChatItem chatItem = ChatItem(
        id: chatId,
        name: name,
        lastMessage: desc.isNotEmpty ? desc : 'Немає повідомлень',
        time: formatTime(createdAt),
        avatar: displayAvatar,
        type: type, 
      );
      
      chatsList.add(chatItem);
    } catch (e) {
      print('Помилка парсингу чату $chatId: $e');
    }
  });
  
  chatsList.sort((a, b) => b.time.compareTo(a.time));
  
  return chatsList;
}

void sendMessage(String text, String userId, String chatId, String type) async {
  final keyPair = await getOrCreateKeyPair();
  final publicKeyPem = encodePublicKeyToPemPKCS1(keyPair.publicKey);

  if (type == "offline") {
    final msg = await ChatDB.addMessage(
      chatId,
      MsgToDb(
        sender: userId,
        content: text,
        time: DateTime.now().toIso8601String(),
      ),
    );

    _onMessageReceived!(msg.toJson());
  } else {
    final dataToEncrypt = jsonEncode({
      'message': {
        'content': text,
        'sender': userId,
        'time': DateTime.now().toIso8601String()
      },
      'chatId': chatId,
      'typeChat': type
    });

    final serverPublicKeyPem = await getServerPublicKey();

    final encrypted = await encryptMessage(dataToEncrypt, serverPublicKeyPem);

    _socket!.emit('send_message', {
      'data': {
        'data': encrypted['data'],
        'key': encrypted['key'],
      },
      'key': publicKeyPem,
      'type': 'mobile',
    });
  }
}

void loadChatContent(String chatId, String type) {
  _socket!.emit('load_chat_content', {
    'chatId': chatId,
    'type': type,
  });
}

void createChatServer(String name, String type, String avatar, String desc, String idServer, String codeServer) {
  _socket!.emit('create_chat_server', {
    'chat': {
      'name': name,
      'description': desc,
      'privacy': type,
      'avatar': avatar,
      'createdAt': DateTime.now().toIso8601String(),
      'idServer': idServer,
    }
  });
}

void createChat(String name, String type, String avatar, String desc) {
  _socket!.emit('create_chat', {
    'chat': {
      'name': name,
      'description': desc,
      'privacy': type,
      'avatar': avatar,
      'createdAt': DateTime.now().toIso8601String()
    }
  });
}

void disconnectSocket() {
  _socket?.disconnect();
  _socket?.dispose();
  _socket = null;
}

bool get isSocketConnected => _socket?.connected ?? false;