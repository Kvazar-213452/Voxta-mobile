import 'package:flutter/material.dart';
import '../models/interface/chat_models.dart';
import 'widgets/chat_list_widget.dart';
import 'widgets/chat_room_widget.dart';
import 'dart:convert';
import '../services/chat/socket_service.dart';
import '../../models/interface/user.dart';

class MainScreen extends StatefulWidget {
  final String responseText;

  const MainScreen({super.key, required this.responseText});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;
  String currentChatName = "Оберіть чат";
  List<Message> messages = [];
  TextEditingController messageController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  
  // Початково порожній список чатів
  List<ChatItem> chats = [];
  
  // Індикатор завантаження
  bool isLoadingChats = true;
  bool isLoadingChatContent = false;
  String? selectedChatId;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  void _initializeSocket() {
    try {
      final userData = jsonDecode(widget.responseText);
      final userJsonMap = jsonDecode(userData['user']);
      final userModel = UserModel.fromJson(userJsonMap);
      
      // Зберігаємо ID поточного користувача
      currentUserId = userModel.id;

      connectSocket(
        userModel, 
        userData['token'], 
        // Callback для повідомлень
        (data) {
          if (mounted) {
            final newMessage = Message(
              text: data['text'] ?? '',
              isOwn: false,
              time: data['time'] ?? TimeOfDay.now().format(context),


                id: DateTime.now().millisecondsSinceEpoch.toString(),
                senderName: null, // Для власних повідомлень ім'я не потрібне
                senderAvatar: null, // Можна додати аватар поточного користувача
                senderId: currentUserId,
            );
            
            setState(() {
              messages.add(newMessage);
            });
          }
        },
        // Callback для чатів
        onChatsReceived: (List<ChatItem> receivedChats) {
          if (mounted) {
            setState(() {
              chats = receivedChats;
              isLoadingChats = false;
            });
            print('✅ Завантажено ${receivedChats.length} чатів');
          }
        },
        // Callback для контенту чату
        onChatContentReceived: (Map<String, dynamic> chatContent) {
          if (mounted) {
            _processChatContent(chatContent);
          }
        },
      );
    } catch (e) {
      print("❌ Помилка ініціалізації: $e");
      setState(() {
        isLoadingChats = false;
      });
    }
  }

  @override
  void dispose() {
    disconnectSocket();
    messageController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1f1f1f),
              Color(0xFF2d2d32),
              Color(0xFF232338),
            ],
          ),
        ),
        child: SafeArea(
          child: currentIndex == 0 
            ? _buildChatListScreen()
            : _buildChatRoomScreen(),
        ),
      ),
    );
  }

  Widget _buildChatListScreen() {
    if (isLoadingChats) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Завантаження чатів...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (chats.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.white54,
            ),
            SizedBox(height: 16),
            Text(
              'Поки немає чатів',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Створіть новий чат або дочекайтеся запрошень',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ChatListWidget(
      chats: chats,
      searchController: searchController,
      onChatTap: _onChatTap,
    );
  }

  Widget _buildChatRoomScreen() {
    if (isLoadingChatContent) {
      return Container(
        color: const Color(0xFF1f1f1f),
        child: Column(
          children: [
            // Заголовок з кнопкою назад
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => currentIndex = 0),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentChatName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Індикатор завантаження
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Завантаження чату...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ChatRoomWidget(
      chatName: currentChatName,
      messages: messages,
      messageController: messageController,
      onBackPressed: () => setState(() => currentIndex = 0),
      onMessageSent: _onMessageSent,
    );
  }

  void _processChatContent(Map<String, dynamic> chatContent) {
    print('Обробка контенту чату: $chatContent');
    
    setState(() {
      isLoadingChatContent = false;
    });

    if (chatContent["code"] == 1 && chatContent.containsKey('messages') && chatContent.containsKey('participants')) {
      List<dynamic> messagesData = chatContent['messages'] ?? [];
      Map<String, dynamic> participants = chatContent['participants'] ?? {};
      
      List<Message> parsedMessages = [];
      
      for (var messageData in messagesData) {
        try {
          String senderId = messageData['sender'].toString();
          String messageId = messageData['_id'] ?? '';
          String content = messageData['content'] ?? '';
          String time = messageData['time'] ?? '';
          
          // Визначаємо чи це повідомлення від поточного користувача
          bool isOwnMessage = senderId == currentUserId;
          
          // Отримуємо дані відправника з participants
          String? senderName;
          String? senderAvatar;
          
          if (participants.containsKey(senderId)) {
            var senderData = participants[senderId];
            senderName = senderData['name'] ?? 'Невідомий';
            senderAvatar = senderData['avatar'] ?? '';
          }
          
          Message message = Message(
            id: messageId,
            text: content,
            isOwn: isOwnMessage,
            time: time,
            senderName: senderName,
            senderAvatar: senderAvatar,
            senderId: senderId,
          );
          
          parsedMessages.add(message);
        } catch (e) {
          print('Помилка парсингу повідомлення: $e');
        }
      }
      
      // Сортуємо повідомлення за часом (можна додати більш складну логіку сортування)
      parsedMessages.sort((a, b) {
        // Простий алфавітний порівняння часу, можна покращити
        return a.time.compareTo(b.time);
      });
      
      setState(() {
        messages = parsedMessages;
      });
      
      print('✅ Завантажено ${parsedMessages.length} повідомлень');
    } else {
      print('❌ Неправильний формат даних чату');
    }
  }

  void _onChatTap(ChatItem chat) {
    setState(() {
      currentIndex = 1;
      currentChatName = chat.name;
      selectedChatId = chat.id;
      // Очищуємо повідомлення для нового чату
      messages = [];
      isLoadingChatContent = true;
    });
    
    // Завантажуємо контент чату з сервера
    _loadChatMessages(chat.id, chat.type);
  }

  void _loadChatMessages(String chatId, String type) {
    print('Завантаження повідомлень для чату: $chatId, тип: $type');
    
    // Відправляємо запит на сервер для завантаження контенту чату
    loadChatContent(chatId, type);
  }

  void _onMessageSent(String messageText) {
    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: messageText,
      isOwn: true,
      time: TimeOfDay.now().format(context),
      senderName: null, // Для власних повідомлень ім'я не потрібне
      senderAvatar: null, // Можна додати аватар поточного користувача
      senderId: currentUserId,
    );
    
    setState(() {
      messages.add(newMessage);
      messageController.clear();
    });

    sendMessage(messageText, currentUserId ?? 'unknown');
  }
}