import 'package:flutter/material.dart';
import '../../../../../models/interface/chat_models.dart';
import '../../../../../app_colors.dart';
import 'delete_message_dialog.dart';
import '../../../../../config.dart';

class MessageWidget extends StatelessWidget {
  static const String baseUrl = Config.URL_SERVICES_DATA;
  
  final Message message;
  final String? chatId;

  const MessageWidget({
    super.key,
    required this.message,
    this.chatId,
  });

  String _getFullUrl(String url) {
    if (url.isEmpty) return url;

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    
    if (url.startsWith('/')) {
      return '$baseUrl$url';
    } else {
      return '$baseUrl/$url';
    }
  }

  String _getMessageText() {
    if (message.text is String) {
      return message.text as String;
    } else {
      return message.text.toString();
    }
  }

  Widget _buildAvatar() {
    if (message.isOwn) {
      return const SizedBox.shrink();
    }

    final String avatarUrl = message.senderAvatar != null && message.senderAvatar!.isNotEmpty
        ? _getFullUrl(message.senderAvatar!)
        : Config.DEF_ICON_USER;

    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.transparent,
      child: ClipOval(
        child: Image.network(
          avatarUrl,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.chatItemBackground,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.loadingIndicator),
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return ClipOval(
              child: Image.network(
                Config.DEF_ICON_USER,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget messageContent = TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 15),
              child: Row(
                mainAxisAlignment:
                    message.isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!message.isOwn) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: _buildAvatar(),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Column(
                      crossAxisAlignment: message.isOwn
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (!message.isOwn && message.senderName != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 4),
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                color: AppColors.whiteText.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              child: Text(message.senderName!),
                            ),
                          ),
                        ],
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: message.isOwn
                                ? AppColors.brandGreen.withOpacity(0.2)
                                : AppColors.whiteText.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: AppColors.whiteText,
                              fontSize: 14,
                            ),
                            child: Text(_getMessageText()),
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: AppColors.whiteText.withOpacity(0.6),
                            fontSize: 11,
                          ),
                          child: Text(message.time),
                        ),
                      ],
                    ),
                  ),
                  if (message.isOwn) ...[
                    const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: _buildAvatar(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );

    if (message.isOwn) {
      return GestureDetector(
        onLongPress: () => DeleteMessageDialog.show(
          context: context,
          message: message,
          chatId: chatId!,
        ),
        child: messageContent,
      );
    }

    return messageContent;
  }
}