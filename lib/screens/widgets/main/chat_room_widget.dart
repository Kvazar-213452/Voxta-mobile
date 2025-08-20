import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import '../../../models/interface/chat_models.dart';
import 'message_widget.dart';
import 'windows/chat_settings/chat_modal_functions.dart';
import '../../../app_colors.dart';
import 'file_picker_service.dart';

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
  double _fileButtonScale = 1.0;
  bool _isUploadingFile = false;
  Map<String, dynamic>? _selectedFileData;

  bool _isUrl(String avatar) {
    return avatar.startsWith('http://') || avatar.startsWith('https://');
  }

  bool _isImageFile(String fileName) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    return imageExtensions.any((ext) => fileName.toLowerCase().endsWith(ext));
  }


Future<void> _downloadFile(String url, String fileName) async {
  try {
    // Отримуємо тимчасову директорію (можна Documents/Downloads)
    final Directory dir = await getApplicationDocumentsDirectory();
    final String filePath = '${dir.path}/$fileName';

    // Завантажуємо файл через HTTP
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      _showSuccessSnackBar('Файл $fileName завантажено в $filePath');
    } else {
      _showErrorSnackBar('Не вдалося завантажити файл (код ${response.statusCode})');
    }
  } catch (e) {
    print('Помилка при завантаженні файлу: $e');
    _showErrorSnackBar('Помилка при завантаженні файлу');
  }
}

  Widget _buildFileMessage(Message message) {
    Map<String, dynamic> fileData;
    
    try {
      if (message.text is String) {
        fileData = json.decode(message.text as String);
      } else if (message.text is Map<String, dynamic>) {
        fileData = message.text as Map<String, dynamic>;
      } else {
        fileData = json.decode(message.text.toString());
      }
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              'Помилка відображення файлу',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      );
    }

    final String url = fileData['url'] ?? '';
    final String name = fileData['name'] ?? 'Невідомий файл';
    final String size = fileData['size']?.toString() ?? '0';
    final bool isImage = _isImageFile(name);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: message.isOwn 
            ? AppColors.brandGreen.withOpacity(0.2)
            : AppColors.whiteText.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.whiteText.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(
                  maxHeight: 200,
                  maxWidth: 250,
                ),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 150,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.brandGreen,
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppColors.whiteText.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            color: AppColors.whiteText.withOpacity(0.6),
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Не вдалося завантажити зображення',
                            style: TextStyle(
                              color: AppColors.whiteText.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
          ] else ...[
            // Відображення іконки файлу
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brandGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getFileIcon(name),
                    color: AppColors.brandGreen,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: AppColors.whiteText,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatFileSize(int.tryParse(size) ?? 0),
                        style: TextStyle(
                          color: AppColors.whiteText.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          
          // Інформація про файл та кнопка завантаження
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: AppColors.whiteText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _formatFileSize(int.tryParse(size) ?? 0),
                      style: TextStyle(
                        color: AppColors.whiteText.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _downloadFile(url, name),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.download,
                        color: AppColors.blackText,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Завантажити',
                        style: TextStyle(
                          color: AppColors.blackText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audio_file;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
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
                          final message = widget.messages[index];
                          
                          // Перевіряємо тип повідомлення
                          if (message.type == "file") {
                            return _buildFileMessage(message);
                          } else {
                            // Звичайне текстове повідомлення
                            return MessageWidget(message: message);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // File Preview (якщо файл вибрано)
            if (_selectedFileData != null)
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 300),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.whiteText.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedFileData!['type'] == 'image' ? Icons.image : Icons.attach_file,
                            color: AppColors.brandGreen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedFileData!['fileName'],
                                  style: TextStyle(
                                    color: AppColors.whiteText,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${(_selectedFileData!['fileSize'] / 1024).toStringAsFixed(1)} KB',
                                  style: TextStyle(
                                    color: AppColors.whiteText.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() => _selectedFileData = null);
                            },
                            child: Icon(
                              Icons.close,
                              color: AppColors.whiteText.withOpacity(0.7),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
                              child: TextField(
                                controller: widget.messageController,
                                style: TextStyle(color: AppColors.whiteText),
                                maxLines: null,
                                minLines: 1,
                                textCapitalization: TextCapitalization.sentences,
                                textInputAction: TextInputAction.newline,
                                keyboardType: TextInputType.multiline,
                                decoration: InputDecoration(
                                  hintText: _selectedFileData != null 
                                      ? 'Додайте опис до файлу...' 
                                      : 'Повідомлення...',
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