import 'package:flutter/material.dart';
import '../models/interface/chat_models.dart';
import 'widgets/main/chat_list_widget.dart';
import 'widgets/main/chat_room_widget.dart';
import 'widgets/main/loading_screen_widget.dart';
import 'widgets/main/empty_state_widget.dart';
import 'widgets/main/app_background.dart';
import '../services/chat/socket_service.dart';
import '../../models/storage_user.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;
  String currentChatName = "Оберіть чат";
  String currentChatAvatar = "";
  List<Message> messages = [];
  TextEditingController messageController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  
  List<ChatItem> chats = [];
  
  bool isLoadingChats = true;
  String? selectedChatId;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  void _initializeSocket() async {
    try {
      final jwt = await getJWTStorage();
      final userModel = await getUserStorage();

      if (userModel == null || jwt == null) {
        print('User or JWT not found!');
        return;
      }
      
      currentUserId = userModel.id;

      connectSocket(
        userModel, 
        jwt,
        (data) {
          if (mounted) {
            final newMessage = Message(
              text: data['text'] ?? '',
              isOwn: false,
              time: data['time'] ?? TimeOfDay.now().format(context),
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              senderName: null,
              senderAvatar: null,
              senderId: currentUserId,
            );
            
            setState(() {
              messages.add(newMessage);
            });
          }
        },

        onChatsReceived: (List<ChatItem> receivedChats) {
          if (mounted) {
            setState(() {
              chats = receivedChats;
              isLoadingChats = false;
            });
          }
        },

        onChatContentReceived: (Map<String, dynamic> chatContent) {
          if (mounted) {
            _processChatContent(chatContent);
          }
        },
      );
    } catch (e) {
      print("Помилка ініціалізації: $e");
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
      body: AppBackground(
        child: currentIndex == 0 
          ? _buildChatListScreen()
          : _buildChatRoomScreen(),
      ),
    );
  }

  Widget _buildChatListScreen() {
    if (isLoadingChats) {
      return const LoadingScreenWidget(
        title: 'Завантаження чатів...',
        subtitle: '',
      );
    }

    if (chats.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.chat_bubble_outline,
        title: 'Поки немає чатів',
        subtitle: 'Створіть новий чат або дочекайтеся запрошень',
      );
    }

    return ChatListWidget(
      chats: chats,
      searchController: searchController,
      onChatTap: _onChatTap,
    );
  }

  Widget _buildChatRoomScreen() {
    return ChatRoomWidget(
      chatName: currentChatName,
      messages: messages,
      messageController: messageController,
      onBackPressed: () => setState(() => currentIndex = 0),
      onMessageSent: _onMessageSent,
      chatAvatar: currentChatAvatar,
    );
  }

  void _processChatContent(Map<String, dynamic> chatContent) {
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
          
          bool isOwnMessage = senderId == currentUserId;
          
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
      
      parsedMessages.sort((a, b) {
        return a.time.compareTo(b.time);
      });
      
      setState(() {
        messages = parsedMessages;
      });
      
      print('✅ Завантажено ${parsedMessages.length} повідомлень');
    } else {
      print('Не можу завантажити чат');
    }
  }

  void _onChatTap(ChatItem chat) {
    setState(() {
      currentIndex = 1;
      currentChatName = chat.name;
      currentChatAvatar = chat.avatar;
      selectedChatId = chat.id;
      messages = [];
    });

    _loadChatMessages(chat.id, chat.type);
  }

  void _loadChatMessages(String chatId, String type) {
    loadChatContent(chatId, type);
  }

  void _onMessageSent(String messageText) {
    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: messageText,
      isOwn: true,
      time: TimeOfDay.now().format(context),
      senderName: null,
      senderAvatar: null,
      senderId: currentUserId,
    );
    
    setState(() {
      messages.add(newMessage);
      messageController.clear();
    });

    sendMessage(messageText, currentUserId ?? 'unknown');
  }
}