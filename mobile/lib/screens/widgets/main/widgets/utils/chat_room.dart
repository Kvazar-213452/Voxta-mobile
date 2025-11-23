import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../../app_colors.dart';

Future<void> downloadFile(String url, String fileName, BuildContext context) async {
  try {
    if (Platform.isAndroid) {
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Немає дозволу на запис у пам'ять"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    Directory? downloadsDir;

    if (Platform.isAndroid) {
      downloadsDir = Directory("/storage/emulated/0/Download");
    } else if (Platform.isIOS) {
      downloadsDir = await getApplicationDocumentsDirectory(); 
    } else {
      downloadsDir = await getDownloadsDirectory();
    }

    if (downloadsDir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Не можу знайти папку завантажень"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String filePath = "${downloadsDir.path}/$fileName";

    // Показуємо індикатор завантаження
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Завантаження файлу..."),
        duration: Duration(seconds: 1),
      ),
    );

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Показуємо успішне повідомлення
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Файл збережено в директорію завантажень"),
          backgroundColor: AppColors.brandGreen,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: AppColors.blackText,
            onPressed: () {},
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Помилка завантаження: ${response.statusCode}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Помилка при завантаженні: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
}

IconData getFileIcon(String fileName) {
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

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
