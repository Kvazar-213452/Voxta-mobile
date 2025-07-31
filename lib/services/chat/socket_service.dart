import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../models/storage_user.dart';
import '../../models/interface/user.dart';
import '../../models/interface/chat_models.dart';
import '../../config.dart';
import 'dart:convert';
import '../../utils/crypto/crypto_app.dart';
import '../../models/storage_key.dart';
import '../../utils/crypto/utils.dart';

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
      print(data);
      
      if (_onMessageReceived != null && data != null) {
        _onMessageReceived!(data as Map<String, dynamic>);
      }
    });

    _socket!.on('authenticated', (data) {
      if (data["code"] == 1) {
        _socket!.emit('getInfoChats', {'chats': data["user"]["chats"]});
      }
    });

    _socket!.on('chats_info', (data) {
      if (data["code"] == 1) {
        List<ChatItem> parsedChats = _parseChatsFromServer(data["chats"]);
        
        if (_onChatsReceived != null) {
          _onChatsReceived!(parsedChats);
        }
      }
    });

    _socket!.on('load_chat_content_return', (data) {
      if (_onChatContentReceived != null) {
        _onChatContentReceived!(data as Map<String, dynamic>);
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
        time: _formatTime(createdAt),
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

String _formatTime(String createdAt) {
  try {
    DateTime dateTime = DateTime.parse(createdAt);
    DateTime now = DateTime.now();
    
    if (dateTime.day == now.day && 
        dateTime.month == now.month && 
        dateTime.year == now.year) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}';
    }
  } catch (e) {
    return 'Невідомо';
  }
}

void sendMessage(String text, String userId, String chatId) async {
  if (_socket != null && _socket!.connected) {
    final keyPair = await getOrCreateKeyPair();
    final publicKeyPem = encodePublicKeyToPemPKCS1(keyPair.publicKey);

    final dataToEncrypt = jsonEncode({
      'message': {
        'content': text,
        'sender': userId,
        'time': DateTime.now().toIso8601String()
      },
      'chatId': chatId,
      'typeChat': 'online'
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
  } else {
    print('❌ Сокет не підключений, неможливо відправити повідомлення');
  }
}

void loadChatContent(String chatId, String type) {
  if (_socket != null && _socket!.connected) {
    _socket!.emit('load_chat_content', {
      'chatId': chatId,
      'type': type,
    });
  } else {
    print('❌ Сокет не підключений, неможливо завантажити контент чату');
  }
}

void disconnectSocket() {
  _socket?.disconnect();
  _socket?.dispose();
  _socket = null;
}

bool get isSocketConnected => _socket?.connected ?? false;
