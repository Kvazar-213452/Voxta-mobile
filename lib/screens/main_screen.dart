import 'package:flutter/material.dart';
import '../models/interface/chat_models.dart';
import 'widgets/main/chat_list_widget.dart';
import 'widgets/main/chat_room_widget.dart';
import 'widgets/main/loading_screen_widget.dart';
import 'widgets/main/empty_state_widget.dart';
import 'widgets/main/app_background.dart';
import 'widgets/main/windows/settings/settings_window.dart';
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
  ScrollController scrollController = ScrollController();
  
  List<ChatItem> chats = [];
  
  bool isLoadingChats = true;
  String? selectedChatId;
  String? currentUserId;
  Map<String, dynamic> currentChatParticipants = {};

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
            print('Обробляємо send_message_return: $data');
            
            // Перевіряємо успішність і отримуємо дані повідомлення
            if (data.containsKey('_id')) {
              Map<String, dynamic> chatData = data;
              
              String messageId = chatData['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
              String content = chatData['content'] ?? '';
              String senderId = chatData['sender'] ?? '';
              String time = chatData['time'] ?? '';
              
              String displayTime = _formatMessageTime(time);
              
              bool isOwnMessage = senderId == currentUserId;
              
              String? senderName;
              String? senderAvatar;
              
              if (currentChatParticipants.containsKey(senderId)) {
                var senderData = currentChatParticipants[senderId];
                senderName = senderData['name'] ?? 'Невідомий';
                senderAvatar = senderData['avatar'] ?? '';
              }
              
              final newMessage = Message(
                id: messageId,
                text: content,
                isOwn: isOwnMessage,
                time: displayTime,
                senderName: senderName,
                senderAvatar: senderAvatar,
                senderId: senderId,
              );
              
              setState(() {
                messages.add(newMessage);
              });
              
              // Автоматично прокручуємо вниз після додавання повідомлення
              _scrollToBottom();
              
              print('✅ Повідомлення додано до інтерфейсу: $content');
            } else {
              print('❌ Помилка відправки повідомлення: ${data['message'] ?? 'Невідома помилка'}');
            }
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

  String _formatMessageTime(String isoTime) {
    try {
      DateTime dateTime = DateTime.parse(isoTime);
      return TimeOfDay.fromDateTime(dateTime).format(context);
    } catch (e) {
      print('Помилка форматування часу: $e для $isoTime');
      return TimeOfDay.now().format(context);
    }
  }

  @override
  void dispose() {
    disconnectSocket();
    messageController.dispose();
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
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
      onSettingsTap: _openSettings,
    );
  }

  Widget _buildChatRoomScreen() {
    return ChatRoomWidget(
      chatName: currentChatName,
      messages: messages,
      messageController: messageController,
      scrollController: scrollController,
      onBackPressed: () => setState(() => currentIndex = 0),
      onMessageSent: _onMessageSent,
      chatAvatar: currentChatAvatar,
    );
  }

  void _processChatContent(Map<String, dynamic> chatContent) {
    if (chatContent["code"] == 1 && chatContent.containsKey('messages') && chatContent.containsKey('participants')) {
      List<dynamic> messagesData = chatContent['messages'] ?? [];
      Map<String, dynamic> participants = chatContent['participants'] ?? {};
      
      currentChatParticipants = participants;
      
      List<Message> parsedMessages = [];
      
      for (var messageData in messagesData) {
        try {
          String senderId = messageData['sender'].toString();
          String messageId = messageData['_id'] ?? '';
          String content = messageData['content'] ?? '';
          String time = messageData['time'] ?? '';
          
          String displayTime = _formatMessageTime(time);
          
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
            time: displayTime,
            senderName: senderName,
            senderAvatar: senderAvatar,
            senderId: senderId,
          );
          
          parsedMessages.add(message);
        } catch (e) {
          print('Помилка парсингу повідомлення: $e');
        }
      }
      
      // Сортуємо повідомлення за оригінальним часом (ISO), а не за відформатованим
      parsedMessages.sort((a, b) {
        try {
          // Отримуємо оригінальний час з messagesData для сортування
          var aData = messagesData.firstWhere((msg) => msg['_id'] == a.id, orElse: () => null);
          var bData = messagesData.firstWhere((msg) => msg['_id'] == b.id, orElse: () => null);
          
          if (aData != null && bData != null) {
            String aTime = aData['time'] ?? '';
            String bTime = bData['time'] ?? '';
            
            DateTime aDateTime = DateTime.parse(aTime);
            DateTime bDateTime = DateTime.parse(bTime);
            
            return aDateTime.compareTo(bDateTime);
          }
        } catch (e) {
          print('Помилка сортування повідомлень: $e');
        }
        
        return 0;
      });
      
      setState(() {
        messages = parsedMessages;
      });
      
      // Прокручуємо вниз після завантаження історії чату
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
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
      currentChatParticipants = {};
    });

    _loadChatMessages(chat.id, chat.type);
  }

  void _loadChatMessages(String chatId, String type) {
    loadChatContent(chatId, type);
  }

  void _onMessageSent(String messageText) {
    sendMessage(messageText, currentUserId ?? 'unknown', selectedChatId ?? '');
    
    messageController.clear();
  }

  void _openSettings() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SettingsScreenWidget(),
    );
  }
}
