import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import '../../../../../app_colors.dart';
import '../../../../../utils/getBase64.dart';

class FilePickerService {
  static final ImagePicker _imagePicker = ImagePicker();

  static void showFilePickerOptions({
    required BuildContext context,
    required String chatId,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(String) onError,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.chatItemBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.whiteText.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Оберіть тип файлу',
                style: TextStyle(
                  color: AppColors.whiteText,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFileOptionButton(
                    context,
                    Icons.photo,
                    'Фото з галереї',
                    () => pickImage(
                      ImageSource.gallery,
                      chatId: chatId,
                      onSuccess: onSuccess,
                      onError: onError,
                    ),
                  ),
                  _buildFileOptionButton(
                    context,
                    Icons.camera_alt,
                    'Зробити фото',
                    () => pickImage(
                      ImageSource.camera,
                      chatId: chatId,
                      onSuccess: onSuccess,
                      onError: onError,
                    ),
                  ),
                  _buildFileOptionButton(
                    context,
                    Icons.attach_file,
                    'Файл',
                    () => pickFile(
                      chatId: chatId,
                      onSuccess: onSuccess,
                      onError: onError,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildFileOptionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.whiteText.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppColors.brandGreen,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.whiteText,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> pickImage(
    ImageSource source, {
    required String chatId,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      final XFile? pickedImage = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );

      if (pickedImage != null) {
        final File imageFile = File(pickedImage.path);
        await processAndSendFile(
          imageFile,
          'image',
          chatId: chatId,
          onSuccess: onSuccess,
          onError: onError,
        );
      }
    } catch (e) {
      onError('Помилка при виборі зображення: $e');
    }
  }

  static Future<void> pickFile({
    required String chatId,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final File file = File(result.files.single.path!);
        await processAndSendFile(
          file,
          'file',
          chatId: chatId,
          onSuccess: onSuccess,
          onError: onError,
        );
      }
    } catch (e) {
      print('Помилка при виборі файлу: $e');
      onError('Помилка при виборі файлу: $e');
    }
  }

  static Future<void> processAndSendFile(
    File file,
    String type, {
    required String chatId,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      final List<int> fileBytes = await file.readAsBytes();
      final String base64String = getFileBase64(file);

      final String fileName = p.basename(file.path);
      final int fileSize = fileBytes.length;

      final Map<String, dynamic> fileData = {
        'fileName': fileName,
        'fileSize': fileSize,
        'base64Data': base64String,
      };

      onSuccess(fileData);
    } catch (e) {
      print('Помилка при обробці файлу: $e');
      onError('Помилка при обробці файлу: $e');
    }
  }
}