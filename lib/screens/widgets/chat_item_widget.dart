import 'package:flutter/material.dart';
import '../../models/interface/chat_models.dart';

class ChatItemWidget extends StatelessWidget {
  final ChatItem chat;
  final int index;
  final VoidCallback onTap;

  const ChatItemWidget({
    super.key,
    required this.chat,
    required this.index,
    required this.onTap,
  });

  // Перевірка чи є аватар URL
  bool _isUrl(String avatar) {
    return avatar.startsWith('http://') || avatar.startsWith('https://');
  }

  // Створення віджету аватару
  Widget _buildAvatar() {
    if (_isUrl(chat.avatar)) {
      // Якщо аватар - це URL
      return CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFF58ff7f),
        child: ClipOval(
          child: Image.network(
            chat.avatar,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFF3d3d3d),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              // Fallback на емодзі якщо зображення не завантажилось
              return Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFF58ff7f),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '👤',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      // Якщо аватар - це емодзі
      return CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFF58ff7f),
        child: Text(
          chat.avatar,
          style: const TextStyle(fontSize: 18),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.transparent),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              child: _buildAvatar(),
                            ),
                            if (chat.isOnline)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF58ff7f),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                child: Text(chat.name),
                              ),
                              const SizedBox(height: 4),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                                child: Text(
                                  chat.lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11,
                          ),
                          child: Text(chat.time),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}