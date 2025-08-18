import 'package:flutter/material.dart';
import '../../../models/interface/chat_models.dart';
import 'message_widget.dart';
import 'windows/chat_settings/chat_modal_functions.dart';
import '../../../app_colors.dart';

class ChatRoomWidget extends StatefulWidget {
  final String chatName;
  final List<Message> messages;
  final TextEditingController messageController;
  final ScrollController scrollController;
  final VoidCallback onBackPressed;
  final Function(String) onMessageSent;
  final String chatAvatar;
  final String type;
  final String id;

  const ChatRoomWidget({
    super.key,
    required this.chatName,
    required this.messages,
    required this.messageController,
    required this.scrollController,
    required this.onBackPressed,
    required this.onMessageSent,
    required this.chatAvatar,
    required this.type,
    required this.id,
  });

  @override
  State<ChatRoomWidget> createState() => _ChatRoomWidgetState();
}

class _ChatRoomWidgetState extends State<ChatRoomWidget> {
  double _sendButtonScale = 1.0;

  bool _isUrl(String avatar) {
    return avatar.startsWith('http://') || avatar.startsWith('https://');
  }

  Widget _buildChatAvatar() {
    if (_isUrl(widget.chatAvatar)) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.transparent,
        child: ClipOval(
          child: Image.network(
            widget.chatAvatar,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.chatItemBackground,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.loadingIndicator),
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return ClipOval(
                child: Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/d/dc/Adolf_Hitler_cropped_restored.jpg',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),
      );
    } else {
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.transparent,
        child: ClipOval(
          child: Image.network(
            'https://upload.wikimedia.org/wikipedia/commons/d/dc/Adolf_Hitler_cropped_restored.jpg',
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Chat Header
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 400),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Transform.translate(
                  offset: Offset(0, -20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.whiteText.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.whiteText.withOpacity(0.1),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: GestureDetector(
                              onTap: widget.onBackPressed,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.whiteText.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.arrow_back,
                                  color: AppColors.whiteText,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            child: _buildChatAvatar(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 300),
                                  style: TextStyle(
                                    color: AppColors.whiteText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  child: Text(widget.chatName),
                                ),
                                const SizedBox(height: 2),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 300),
                                  style: TextStyle(
                                    color: AppColors.whiteText.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                  child: const Text('онлайн'),
                                ),
                              ],
                            ),
                          ),
                          _buildHeaderButton(Icons.more_vert, () => ChatModalFunctions.showChatOptionsModal(
                            context,
                            type: widget.type,
                            id: widget.id,
                            chatAvatar: _buildChatAvatar(),
                            onBackPressed: widget.onBackPressed,
                          )),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Messages
            Expanded(
              child: TweenAnimationBuilder(
                duration: const Duration(milliseconds: 500),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: ListView.builder(
                        controller: widget.scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: widget.messages.length,
                        itemBuilder: (context, index) {
                          return MessageWidget(message: widget.messages[index]);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Message Input
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 600),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.whiteText.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: TextField(
                                controller: widget.messageController,
                                style: TextStyle(color: AppColors.whiteText),
                                decoration: InputDecoration(
                                  hintText: 'Напишіть повідомлення...',
                                  hintStyle: TextStyle(
                                    color: AppColors.whiteText.withOpacity(0.6),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          AnimatedScale(
                            duration: const Duration(milliseconds: 150),
                            scale: _sendButtonScale,
                            child: GestureDetector(
                              onTapDown: (_) => setState(() => _sendButtonScale = 0.9),
                              onTapUp: (_) => setState(() => _sendButtonScale = 1.0),
                              onTapCancel: () => setState(() => _sendButtonScale = 1.0),
                              onTap: _sendMessage,
                              child: Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: AppColors.brandGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.send,
                                  color: AppColors.blackText,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton(IconData icon, VoidCallback onTap) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: 1.0,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.whiteText.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.whiteText.withOpacity(0.1)),
            ),
            child: Icon(
              icon,
              color: AppColors.whiteText,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  void _sendMessage() {
    if (widget.messageController.text.trim().isNotEmpty) {
      widget.onMessageSent(widget.messageController.text.trim());
      setState(() => _sendButtonScale = 1.0);
    }
  }
}

// widget.onBackPressed