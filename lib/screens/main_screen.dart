import 'package:flutter/material.dart';
import '../models/interface/chat_models.dart';
import 'widgets/chat_list_widget.dart';
import 'widgets/chat_room_widget.dart';

class MainScreen extends StatefulWidget {
  final String responseText;

  const MainScreen({super.key, required this.responseText});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int currentIndex = 0;
  String currentChatName = "Оберіть чат";
  List<Message> messages = [];
  TextEditingController messageController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  
  List<ChatItem> chats = [
    ChatItem(
      id: '1',
      name: 'Олександр',
      lastMessage: 'Привіт! Як справи?',
      time: '12:30',
      avatar: '👨‍💻',
      isOnline: true,
    ),
    ChatItem(
      id: '2', 
      name: 'Марія',
      lastMessage: 'До зустрічі завтра',
      time: '11:45',
      avatar: '👩‍🎨',
      isOnline: false,
    ),
    ChatItem(
      id: '3',
      name: 'Групова розмова',
      lastMessage: 'Хтось є онлайн?',
      time: '10:20',
      avatar: '👥',
      isOnline: true,
    ),
  ];

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
            ? ChatListWidget(
                chats: chats,
                searchController: searchController,
                onChatTap: _onChatTap,
              )
            : ChatRoomWidget(
                chatName: currentChatName,
                messages: messages,
                messageController: messageController,
                onBackPressed: _onBackPressed,
                onMessageSent: _onMessageSent,
              ),
        ),
      ),
    );
  }

  void _onChatTap(ChatItem chat) {
    setState(() {
      currentIndex = 1;
      currentChatName = chat.name;
      // Додаємо кілька тестових повідомлень
      messages = [
        Message(
          text: 'Привіт! Як справи?',
          isOwn: false,
          time: '12:30',
        ),
        Message(
          text: 'Привіт! Все добре, дякую. А у тебе як?',
          isOwn: true,
          time: '12:32',
        ),
        Message(
          text: 'Теж все супер! Працюю над новим проектом',
          isOwn: false,
          time: '12:35',
        ),
      ];
    });
  }

  void _onBackPressed() {
    setState(() => currentIndex = 0);
  }

  void _onMessageSent(String messageText) {
    final newMessage = Message(
      text: messageText,
      isOwn: true,
      time: TimeOfDay.now().format(context),
    );
    
    setState(() {
      messages.add(newMessage);
      messageController.clear();
    });
  }
}