import 'package:flutter/material.dart';
import '../../../../models/interface/chat_models.dart';
import '../../../../app_colors.dart';
import '../../../../config.dart';

class ChatItemWidget extends StatelessWidget {
  static const String baseUrl = Config.URL_SERVICES_DATA;
  
  final ChatItem chat;
  final int index;
  final VoidCallback onTap;

  const ChatItemWidget({
    super.key,
    required this.chat,
    required this.index,
    required this.onTap,
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

  Widget _buildAvatar() {
    final String avatarUrl = chat.avatar.isNotEmpty
        ? _getFullUrl(chat.avatar)
        : Config.DEF_ICON_USER;
    
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.chatItemBackground,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.network(
          avatarUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.chatItemBackground,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.loadingIndicator),
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.chatItemBackground,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.person,
                  size: 24,
                  color: AppColors.whiteText.withOpacity(0.6),
                ),
              ),
            );
          },
        ),
      ),
    );
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
                color: AppColors.whiteText.withOpacity(0.1),
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
                          ],
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  color: AppColors.whiteText,
                                  fontWeight: FontWeight.w600,
                                ),
                                child: Text(chat.name),
                              ),
                              const SizedBox(height: 4),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  color: AppColors.whiteText.withOpacity(0.6),
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
                            color: AppColors.whiteText.withOpacity(0.6),
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