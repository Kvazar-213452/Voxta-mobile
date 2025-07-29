import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../models/storage_user.dart';
import '../../models/interface/user.dart';
import '../../models/interface/chat_models.dart';

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
    _socket = IO.io('http://192.168.68.101:3001', 
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .setTimeout(10000)
        .build()
    );

    _socket!.onConnect((_) {
      print('Підключено до сокет-серверу');
      _socket!.emit('authenticate', {'token': token});
    });

    _socket!.on('message', (data) {
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
        print('Отримані чати: ${data["chats"]}');
        
        // Парсинг чатів з серверних даних
        List<ChatItem> parsedChats = _parseChatsFromServer(data["chats"]);
        
        // Передача чатів в UI
        if (_onChatsReceived != null) {
          _onChatsReceived!(parsedChats);
        }
      }
    });

    _socket!.on('load_chat_content_return', (data) {
      print('Отримано контент чату: $data');
      
      // Передача контенту чату в UI
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

// Функція для парсингу чатів з серверних даних
List<ChatItem> _parseChatsFromServer(Map<String, dynamic> chatsData) {
  List<ChatItem> chatsList = [];
  
  chatsData.forEach((chatId, chatInfo) {
    try {
      // Парсинг даних чату
      String name = chatInfo['name'] ?? 'Невідомий чат';
      String avatar = chatInfo['avatar'] ?? '';
      String type = chatInfo['type'] ?? 'offline';
      String desc = chatInfo['desc'] ?? '';
      String createdAt = chatInfo['createdAt'] ?? '';
      List<dynamic> participants = chatInfo['participants'] ?? [];
      
      // Визначення онлайн статусу
      bool isOnline = type == 'online';
      
      // Використання URL аватару або fallback емодзі
      String displayAvatar = avatar.isNotEmpty ? avatar : _getAvatarFromName(name);
      
      // Створення ChatItem
      ChatItem chatItem = ChatItem(
        id: chatId,
        name: name,
        lastMessage: desc.isNotEmpty ? desc : 'Немає повідомлень',
        time: _formatTime(createdAt),
        avatar: displayAvatar,
        isOnline: isOnline,
        type: type, // Додане поле
      );
      
      chatsList.add(chatItem);
    } catch (e) {
      print('Помилка парсингу чату $chatId: $e');
    }
  });
  
  // Сортування чатів за часом створення (новіші спочатку)
  chatsList.sort((a, b) => b.time.compareTo(a.time));
  
  return chatsList;
}

// Допоміжна функція для створення аватару з імені (fallback)
String _getAvatarFromName(String name) {
  if (name.isEmpty) return '💬';
  
  // Створення емодзі на основі першої літери
  final Map<String, String> avatarMap = {
    'а': '👨‍💻', 'б': '👩‍🎨', 'в': '👨‍🔧', 'г': '👩‍🏫', 'д': '👨‍⚕️',
    'е': '👩‍💼', 'ж': '👨‍🎤', 'з': '👩‍🔬', 'и': '👨‍🍳', 'к': '👩‍✈️',
    'л': '👨‍🌾', 'м': '👩‍💻', 'н': '👨‍🎨', 'о': '👩‍🔧', 'п': '👨‍🏫',
    'р': '👩‍⚕️', 'с': '👨‍💼', 'т': '👩‍🎤', 'у': '👨‍🔬', 'ф': '👩‍🍳',
    'х': '👨‍✈️', 'ц': '👩‍🌾', 'ч': '🧑‍💻', 'ш': '🧑‍🎨', 'я': '👤',
  };
  
  String firstLetter = name.toLowerCase().substring(0, 1);
  return avatarMap[firstLetter] ?? '👤';
}

// Допоміжна функція для форматування часу
String _formatTime(String createdAt) {
  try {
    DateTime dateTime = DateTime.parse(createdAt);
    DateTime now = DateTime.now();
    
    if (dateTime.day == now.day && 
        dateTime.month == now.month && 
        dateTime.year == now.year) {
      // Якщо сьогодні - показуємо час
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      // Якщо не сьогодні - показуємо дату
      return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}';
    }
  } catch (e) {
    return 'Невідомо';
  }
}

void sendMessage(String text, String userId) {
  if (_socket != null && _socket!.connected) {
    _socket!.emit('message', {
      'text': text,
      'userId': userId,
      'time': DateTime.now().toIso8601String(),
    });
  }
}

void loadChatContent(String chatId, String type) {
  if (_socket != null && _socket!.connected) {
    print('Завантаження контенту чату: $chatId, тип: $type');
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