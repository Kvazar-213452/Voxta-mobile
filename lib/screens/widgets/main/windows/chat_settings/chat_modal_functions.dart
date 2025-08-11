import 'package:flutter/material.dart';
import 'chat_settings_modal.dart';
import 'utils.dart';

class ChatModalFunctions {
  static void showChatOptionsModal(
    BuildContext context, {
    required String id,
    required String type,
    required Widget chatAvatar,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF58FF7F)),
          ),
        );
      },
    );

    getInfoChat(
      id: id,
      type: type,
      onSuccess: (String chatName, String description, Map<String, dynamic> data) {
        Navigator.pop(context);
        
        _showOptionsModal(context, 
          id: id, 
          type: type, 
          chatName: chatName, 
          chatAvatar: chatAvatar
        );
      },
      onError: (String error) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка завантаження: $error'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      },
    );
  }

  static void _showOptionsModal(
    BuildContext context, {
    required String id,
    required String type,
    required String chatName,
    required Widget chatAvatar,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2d2d2d),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle indicator
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      child: chatAvatar,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chatName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            type,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Divider
              Container(
                height: 1,
                color: Colors.white.withOpacity(0.1),
              ),
              
              // Options
              _buildModalOption(
                icon: Icons.settings,
                title: 'Налаштування',
                onTap: () {
                  Navigator.pop(context);
                  _loadAndShowChatSettings(context, id: id, type: type);
                },
              ),
              
              _buildModalOption(
                icon: Icons.block,
                title: 'Заблокувати',
                onTap: () {
                  Navigator.pop(context);
                  showBlockDialog(context, chatName: chatName);
                },
                isDestructive: true,
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildModalOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive 
                  ? Colors.red.shade400 
                  : Colors.white.withOpacity(0.8),
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: isDestructive 
                    ? Colors.red.shade400 
                    : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showBlockDialog(BuildContext context, {required String chatName}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2d2d2d),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Заблокувати $chatName?',
            style: const TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Ви не зможете отримувати повідомлення від цього користувача.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Скасувати',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Додайте логіку для блокування
              },
              child: Text(
                'Заблокувати',
                style: TextStyle(color: Colors.red.shade400),
              ),
            ),
          ],
        );
      },
    );
  }

  static void _loadAndShowChatSettings(
    BuildContext context, {
    required String id,
    required String type,
  }) {
    // Показуємо індикатор завантаження
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF58FF7F)),
          ),
        );
      },
    );

    // Запитуємо інформацію про чат
    getInfoChat(
      id: id,
      type: type,
      onSuccess: (String name, String description, Map<String, dynamic> data) {
        Navigator.pop(context);
        
        showChatSettingsModal(
          context,
          chatName: name,
          currentDescription: description,
          id: id,
          type: type,
          avatarUrl: data["avatar"],
          users: data["participants"] ?? [],
          owner: data["owner"] ?? "",
          time: data["createdAt"] ?? "",
        );
      },
      onError: (String error) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка завантаження: $error'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      },
    );
  }

  static Future<void> showChatSettingsModal(
    BuildContext context, {
    required String chatName,
    required String currentDescription,
    required String id,
    required String type,
    required String time,
    required String owner,
    required String? avatarUrl,
    required List<dynamic> users,
  }) async {
    Widget? avatarWidget;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      avatarWidget = Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.group,
            color: Color(0xFF58FF7F),
          );
        },
      );
    }

    String keyChat = '';

    try {
      keyChat = await getKeyChat(id);
    } catch (e) {
      print("error: $e");
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return ChatSettingsModal(
          currentName: chatName,
          currentDescription: currentDescription,
          chatAvatar: avatarWidget,
          users: users,
          typeChat: type,
          time: time,
          owner: owner,
          chatId: id,
          currentInviteCode: keyChat,
          onSave: (String newName, String newDescription, String? avatarBase64) {
            saveSettingsChat(id, type, {
              "name": newName,
              "desc": newDescription,
              "avatar": avatarBase64
            });
          },
        );
      },
    );
  }
}

// ChatSettingsModal