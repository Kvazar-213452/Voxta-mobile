import 'package:flutter/material.dart';
import '../../../../models/interface/chat_models.dart';
import 'component/message_widget.dart';
import '../windows/chat_settings/chat_modal_functions.dart';
import '../../../../app_colors.dart';
import 'component/file_picker_service.dart';
import 'component/file_message_builder.dart';
import '../../../../config.dart';

class ChatRoomWidget extends StatefulWidget {
  final String chatName;
  final List<Message> messages;
  final TextEditingController messageController;
  final ScrollController scrollController;
  final VoidCallback onBackPressed;
  final Function(String, {Map<String, dynamic>? fileData}) onMessageSent;
  final String chatAvatar;
  final String type;
  final String id;
  final String owner;

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
    required this.owner,
  });

  @override
  State<ChatRoomWidget> createState() => _ChatRoomWidgetState();
}

class _ChatRoomWidgetState extends State<ChatRoomWidget> {
  static const String baseUrl = Config.URL_SERVICES_DATA;
  double _sendButtonScale = 1.0;
  double _fileButtonScale = 1.0;
  bool _isUploadingFile = false;
  Map<String, dynamic>? _selectedFileData;

  bool _isUrl(String avatar) {
    return avatar.startsWith('http://') || avatar.startsWith('https://');
  }

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

  Widget _buildChatAvatar() {
    final String avatarUrl = _getFullUrl(widget.chatAvatar);
    
    if (_isUrl(avatarUrl)) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.transparent,
        child: ClipOval(
          child: Image.network(
            avatarUrl,
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
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.chatItemBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.whiteText.withOpacity(0.7),
                ),
              );
            },
          ),
        ),
      );
    } else {
      return CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.chatItemBackground,
        child: Icon(
          Icons.person,
          color: AppColors.whiteText.withOpacity(0.7),
        ),
      );
    }
  }

  void _showFilePickerOptions() {
    setState(() => _isUploadingFile = true);
    
    FilePickerService.showFilePickerOptions(
      context: context,
      chatId: widget.id,
      onSuccess: (fileData) {
        setState(() {
          _isUploadingFile = false;
          _selectedFileData = fileData;
        });
        _showSuccessSnackBar('Файл успішно вибрано: ${fileData['fileName']}');
        
        _sendMessage();
      },
      onError: (error) {
        setState(() => _isUploadingFile = false);
        _showErrorSnackBar(error);
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.brandGreen,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
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
                                  child: Text(widget.type),
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
                            owner: widget.owner,
                          )),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

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
                          final message = widget.messages[index];

                          if (message.type == "file") {
                            return FileMessageBuilder.buildFileMessage(
                              message, 
                              chatId: widget.id,
                              context: context,
                            );
                          } else {
                            return MessageWidget(
                              message: message,
                              chatId: widget.id,
                            );
                          }
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
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AnimatedScale(
                            duration: const Duration(milliseconds: 150),
                            scale: _fileButtonScale,
                            child: GestureDetector(
                              onTapDown: (_) => setState(() => _fileButtonScale = 0.9),
                              onTapUp: (_) => setState(() => _fileButtonScale = 1.0),
                              onTapCancel: () => setState(() => _fileButtonScale = 1.0),
                              onTap: _isUploadingFile ? null : _showFilePickerOptions,
                              child: Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: AppColors.whiteText.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: _isUploadingFile
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            AppColors.brandGreen,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.attach_file,
                                        color: AppColors.whiteText.withOpacity(0.8),
                                        size: 20,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          
                          Expanded(
                            child: Container(
                              constraints: BoxConstraints(
                                minHeight: 45,
                                maxHeight: 150,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.whiteText.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Scrollbar(
                                child: TextField(
                                  controller: widget.messageController,
                                  style: TextStyle(color: AppColors.whiteText),
                                  maxLines: null,
                                  minLines: 1,
                                  textCapitalization: TextCapitalization.sentences,
                                  textInputAction: TextInputAction.newline,
                                  keyboardType: TextInputType.multiline,
                                  scrollPhysics: const BouncingScrollPhysics(),
                                  decoration: InputDecoration(
                                    hintText: 'Повідомлення...',
                                    hintStyle: TextStyle(
                                      color: AppColors.whiteText.withOpacity(0.6),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    isDense: true,
                                  ),
                                  onSubmitted: (value) {
                                    _sendMessage();
                                  },
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
    final String messageText = widget.messageController.text.trim();

    if (_selectedFileData != null || messageText.isNotEmpty) {
      widget.onMessageSent(
        messageText, 
        fileData: _selectedFileData,
      );
      
      widget.messageController.clear();
      setState(() {
        _selectedFileData = null;
        _sendButtonScale = 1.0;
      });
    }
  }
}