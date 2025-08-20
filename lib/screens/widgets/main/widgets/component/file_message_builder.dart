import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../../../models/interface/chat_models.dart';
import '../../../../../app_colors.dart';
import '../utils/chat_room.dart';

class FileMessageBuilder {
  static bool _isImageFile(String fileName) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    return imageExtensions.any((ext) => fileName.toLowerCase().endsWith(ext));
  }

  static Widget buildFileMessage(Message message) {
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
      return _buildErrorMessage();
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
          if (isImage) 
            _buildImagePreview(url)
          else 
            _buildFilePreview(name, size),
          
          const SizedBox(height: 8),
          
          // Інформація про файл та кнопка завантаження
          _buildFileInfo(name, size, url),
        ],
      ),
    );
  }

  static Widget _buildErrorMessage() {
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

  static Widget _buildImagePreview(String url) {
    return ClipRRect(
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
    );
  }

  static Widget _buildFilePreview(String name, String size) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.brandGreen.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            getFileIcon(name),
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
                formatFileSize(int.tryParse(size) ?? 0),
                style: TextStyle(
                  color: AppColors.whiteText.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildFileInfo(String name, String size, String url) {
    return Row(
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
                formatFileSize(int.tryParse(size) ?? 0),
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
          onTap: () => downloadFile(url, name),
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
    );
  }
}