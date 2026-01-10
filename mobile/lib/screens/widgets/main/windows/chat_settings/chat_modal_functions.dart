import 'package:flutter/material.dart';
import '../../../../../app_colors.dart';
import 'chat_settings_modal.dart';
import 'set_key_modal.dart';
import 'utils.dart';
import '../../../../../services/chat/socket_service.dart';
import '../../../../../models/storage_user.dart';

class ChatModalFunctions {
  static void showChatOptionsModal(
    BuildContext context, {
    required String id,
    required String owner,
    required String type,
    required Widget chatAvatar,
    required VoidCallback onBackPressed,
  }) {
    if (!context.mounted) return;

    getInfoChat(
      id: id,
      type: type,
      onSuccess: (
        String chatName,
        String description,
        Map<String, dynamic> data,
      ) {
        if (!context.mounted) return;

        _showOptionsModal(
          context,
          id: id,
          type: type,
          chatName: chatName,
          chatAvatar: chatAvatar,
          onBackPressed: onBackPressed,
          owner: owner,
        );
      },
      onError: (String error) {
        if (!context.mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка завантаження: $error'),
            backgroundColor: AppColors.destructiveRed,
            duration: const Duration(seconds: 3),
          ),
        );
      },
    );
  }

  static void _showOptionsModal(
    BuildContext context, {
    required String id,
    required String owner,
    required String type,
    required String chatName,
    required Widget chatAvatar,
    required VoidCallback onBackPressed,
  }) {
    if (!context.mounted) return;
    
    final parentContext = context;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext context) {
        return FutureBuilder(
          future: getUserStorage(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.modalBackground,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final user = snapshot.data;

            return Container(
              decoration: BoxDecoration(
                color: AppColors.modalBackground,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border.all(color: AppColors.modalBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.modalHandle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 20, child: chatAvatar),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chatName,
                                style: TextStyle(
                                  color: AppColors.whiteText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                type,
                                style: TextStyle(
                                  color: AppColors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(height: 1, color: AppColors.modalDivider),

                  if (user != null && owner == user.id)
                    _buildModalOption(
                      icon: Icons.settings,
                      title: 'Налаштування',
                      onTap: () {
                        Navigator.pop(context);
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (!parentContext.mounted) return;
                          _loadAndShowChatSettings(
                            parentContext,
                            id: id,
                            type: type,
                            onBackPressed: onBackPressed,
                          );
                        });
                      },
                    ),

                  _buildModalOption(
                    icon: Icons.key,
                    title: 'Встановити ключ',
                    onTap: () {
                      Navigator.pop(context);
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (!parentContext.mounted) return;
                        _showSetKeyModal(
                          parentContext,
                          chatId: id,
                          chatName: chatName,
                        );
                      });
                    },
                    isDestructive: false,
                  ),

                  _buildModalOption(
                    icon: Icons.exit_to_app,
                    title: 'Вийти',
                    onTap: () {
                      Navigator.pop(context);
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (!parentContext.mounted) return;
                        showBlockDialog(
                          onBackPressed,
                          id,
                          type,
                          parentContext,
                          chatName: chatName,
                        );
                      });
                    },
                    isDestructive: true,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
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
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    isDestructive
                        ? AppColors.destructiveRed
                        : AppColors.white70,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color:
                      isDestructive
                          ? AppColors.destructiveRed
                          : AppColors.whiteText,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: AppColors.white54, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  static void _showSetKeyModal(
    BuildContext context, {
    required String chatId,
    required String chatName,
  }) {
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      barrierColor: AppColors.overlayBackground,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return SetKeyModal(
          chatId: chatId,
          chatName: chatName,
          onClose: () {},
        );
      },
    );
  }

  static void showBlockDialog(
    VoidCallback onBackPressed,
    String id,
    String type,
    BuildContext context, {
    required String chatName,
  }) {
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.modalBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Вийти $chatName?',
            style: TextStyle(color: AppColors.whiteText),
          ),
          content: Text(
            'Ви вийдете з цього чату',
            style: TextStyle(color: AppColors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Скасувати',
                style: TextStyle(color: AppColors.white70),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await delSelfInChat(id, type);
                  await loadChats();
                  onBackPressed();
                } catch (e) {
                  print('Error leaving chat: $e');
                }
              },
              child: Text(
                'Вийти',
                style: TextStyle(color: AppColors.destructiveRed),
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
    required VoidCallback onBackPressed,
  }) {
    if (!context.mounted) return;

    getInfoChat(
      id: id,
      type: type,
      onSuccess: (String name, String description, Map<String, dynamic> data) {
        if (!context.mounted) return;

        showChatSettingsModal(
          context,
          chatName: name,
          currentDescription: description,
          id: id,
          onBackPressed: onBackPressed,
          type: type,
          avatarUrl: data["avatar"],
          users: data["participants"] ?? [],
          owner: data["owner"] ?? "",
          time: data["createdAt"] ?? "",
        );
      },
      onError: (String error) {
        print('onError: $error');
        
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка завантаження: $error'),
            backgroundColor: AppColors.destructiveRed,
            duration: const Duration(seconds: 3),
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
    required VoidCallback onBackPressed,
    required List<dynamic> users,
  }) async {
    if (!context.mounted) return;
    
    Widget? avatarWidget;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      avatarWidget = Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.group, color: AppColors.brandGreen);
        },
      );
    }

    String keyChat = '';

    try {
      keyChat = await getKeyChat(id);
    } catch (e) {
      print("error getting key: $e");
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierColor: AppColors.overlayBackground,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ChatSettingsModal(
          currentName: chatName,
          currentDescription: currentDescription,
          chatAvatar: avatarWidget,
          onBackPressed: onBackPressed,
          users: users,
          typeChat: type,
          time: time,
          owner: owner,
          chatId: id,
          currentInviteCode: keyChat,
          onSave: (
            String newName,
            String newDescription,
            String? avatarBase64,
          ) {
            saveSettingsChat(id, type, {
              "name": newName,
              "desc": newDescription,
              "avatar": avatarBase64,
            });
          },
        );
      },
    );
  }
}