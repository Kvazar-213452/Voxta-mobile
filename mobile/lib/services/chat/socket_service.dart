import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../models/storage_user.dart';
import '../../models/interface/user.dart';
import '../../models/interface/chat_models.dart';
import '../../config.dart';
import 'utils.dart';
import '../../utils/crypto/crypto_auto.dart';
import '../../models/storage_chat_key.dart';
import '../../utils/crypto/crypto_msg.dart';

IO.Socket? socket;
Function(Map<String, dynamic>)? _onMessageReceived;
Function()? _onReloadChatContent;
Function(List<ChatItem>)? _onChatsReceived;
Function(Map<String, dynamic>)? _onChatContentReceived;

void connectSocket(
  UserModel user,
  String token,
  Function(Map<String, dynamic>) onMessageReceived,
  Function() onReloadChatContent, {
  Function(List<ChatItem>)? onChatsReceived,
  Function(Map<String, dynamic>)? onChatContentReceived,
}) {
  _onMessageReceived = onMessageReceived;
  _onReloadChatContent = onReloadChatContent;
  _onChatsReceived = onChatsReceived;
  _onChatContentReceived = onChatContentReceived;
  saveUserStorage(user);

  String CAHT_ID = "";

  try {
    socket = IO.io(
      Config.URL_SERVICES_CHAT,
      IO.OptionBuilder().setTransports(['websocket']).setTimeout(10000).build(),
    );

    socket!.onConnect((_) async {
      print('Підключено до сокет-серверу');

      socket!.emit('authenticate', await encrypt_auto({'token': token}));
    });

    socket!.on('send_message_return', (data) async {
      data = await decrypted_auto(data);
      data = await decryptMessage(data, CAHT_ID);

      _onMessageReceived!(data as Map<String, dynamic>);
    });

    socket!.on('del_msg', (data) async {
      _onReloadChatContent!();
    });

    socket!.on('authenticated', (data) async {
      data = await decrypted_auto(data);

      if (data["code"] == 1) {
        await loadChats();
      }
    });

    socket!.on('chats_info', (data) async {
      data = await decrypted_auto(data);

      if (data["code"] == 1) {
        List<ChatItem> parsedChats = _parseChatsFromServer(data["chats"]);

        _onChatsReceived!(parsedChats);
      }
    });

    socket!.on('load_chat_content_return', (data) async {
      data = await decrypted_auto(data);
      data = await decryptMessages(data);

      CAHT_ID = data["chatId"];

      _onChatContentReceived!(data as Map<String, dynamic>);
    });

    socket!.on('create_new_chat', (data) async {
      await loadChats();
    });

    socket!.on('get_info_self', (data) async {
      data = await decrypted_auto(data);

      if (data['type'] == "load_chats") {
        final userMap = data['user'];
        if (userMap != null && userMap is Map<String, dynamic>) {
          UserModel user = UserModel.fromJson(userMap);
          await saveUserStorage(user);

          socket!.emit(
            'getInfoChats',
            await encrypt_auto({'chats': user.chats}),
          );
        } else {
          print("user is null");
        }
      }
    });

    socket!.onDisconnect((reason) {
      print('Відключено від сервера: $reason');
    });

    socket!.connect();
  } catch (e) {
    print('Помилка підключення: $e');
  }
}

Future<void> loadChats() async {
  socket!.emit('get_info_self', await encrypt_auto({'type': 'load_chats'}));
}

List<ChatItem> _parseChatsFromServer(Map<String, dynamic> chatsData) {
  List<ChatItem> chatsList = [];

  chatsData.forEach((chatId, chatInfo) {
    try {
      String name = chatInfo['name'] ?? 'Невідомий чат';
      String avatar = chatInfo['avatar'] ?? '';
      String type = chatInfo['type'] ?? '';
      String desc = chatInfo['desc'] ?? '';
      String owner = chatInfo['owner'] ?? '';
      String createdAt = chatInfo['createdAt'] ?? '';

      String displayAvatar = avatar.isNotEmpty ? avatar : "";

      ChatItem chatItem = ChatItem(
        id: chatId,
        name: name,
        lastMessage: desc.isNotEmpty ? desc : 'Немає повідомлень',
        time: formatTime(createdAt),
        avatar: displayAvatar,
        type: type,
        owner: owner,
      );

      chatsList.add(chatItem);
    } catch (e) {
      print('Помилка парсингу чату $chatId: $e');
    }
  });

  chatsList.sort((a, b) => b.time.compareTo(a.time));

  return chatsList;
}

void sendMessage(
  Object text,
  String userId,
  String chatId,
  String type,
  String typeMsg,
) async {
  String keyChat = await ChatKeysDB.getKey(chatId);

  if (keyChat != "") {
    text = encryptText(text.toString(), keyChat);
  }

  final dataToEncrypt = {
    'message': {
      'content': text,
      'sender': userId,
      'type': typeMsg,
      'time': DateTime.now().toIso8601String(),
    },
    'chatId': chatId,
    'typeChat': type,
  };

  socket!.emit('send_message', await encryptAutoServer(dataToEncrypt));
}

void loadChatContent(String chatId, String type) async {
  socket!.emit(
    'load_chat_content',
    await encrypt_auto({'chatId': chatId, 'type': type}),
  );
}

void createChatServer(
  String name,
  String type,
  String avatar,
  String desc,
  String idServer,
  String codeServer,
) {
  socket!.emit('create_chat_server', {
    'chat': {
      'name': name,
      'description': desc,
      'privacy': type,
      'avatar': avatar,
      'createdAt': DateTime.now().toIso8601String(),
      'idServer': idServer,
    },
  });
}

void createChat(String name, String type, String avatar, String desc) async {
  final dataCrypto = {
    'chat': {
      'name': name,
      'description': desc,
      'privacy': type,
      'avatar': avatar,
      'createdAt': DateTime.now().toIso8601String(),
    },
  };

  socket!.emit('create_chat', await encrypt_auto(dataCrypto));
}

void disconnectSocket() {
  socket?.disconnect();
  socket?.dispose();
  socket = null;
}

void createTemporaryChat(
  String chatName,
  String privacy,
  String avatarBase64,
  String chatDescription,
  int expirationHours,
  String password,
) async {
  final expirationDate = DateTime.now().add(Duration(hours: expirationHours)).toIso8601String();

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

  socket!.emit('create_temporary_chat', await encrypt_auto(chatData));
}

bool get isSocketConnected => socket?.connected ?? false;