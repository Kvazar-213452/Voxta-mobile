import 'package:flutter/material.dart';
import '../../models/interface/chat_models.dart';

class MessageWidget extends StatelessWidget {
  final Message message;

  const MessageWidget({
    super.key,
    required this.message,
  });

  // Перевірка чи є аватар URL
  bool _isUrl(String? avatar) {
    if (avatar == null || avatar.isEmpty) return false;
    return avatar.startsWith('http://') || avatar.startsWith('https://');
  }

  // Створення віджету аватару
  Widget _buildAvatar() {
    if (_isUrl(message.senderAvatar)) {
      // Якщо аватар - це URL
      return CircleAvatar(
        radius: 16,
        backgroundColor: const Color(0xFF58ff7f),
        child: ClipOval(
          child: Image.network(
            message.senderAvatar!,
            width: 32,
            height: 32,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF3d3d3d),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              // Fallback на емодзі якщо зображення не завантажилось
              return Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF58ff7f),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '👤',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      // Fallback аватар
      return CircleAvatar(
        radius: 16,
        backgroundColor: const Color(0xFF58ff7f),
        child: Text(
          _getAvatarFromName(message.senderName ?? ''),
          style: const TextStyle(fontSize: 12),
        ),
      );
    }
  }

  String _getAvatarFromName(String name) {
    if (name.isEmpty) return '👤';

    return '👤';
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
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
                        // Показуємо ім'я відправника для не власних повідомлень
                        if (!message.isOwn && message.senderName != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 4),
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
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
                                ? const Color(0xFF58ff7f).withOpacity(0.2)
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            child: Text(message.text),
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
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
  }
}