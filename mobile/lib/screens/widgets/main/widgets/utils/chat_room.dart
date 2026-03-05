import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../../../models/storage_chat_key.dart';
import '../../../../../utils/crypto/crypto_msg.dart';
import 'dart:typed_data';

Future<void> downloadFile(
  String url,
  String fileName,
  String chatId,
  BuildContext context,
) async {
  try {
    final keyChat = await ChatKeysDB.getKeyAES(chatId);

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception("HTTP ${response.statusCode}");
    }

    Directory baseDir;
    if (Platform.isAndroid) {
      baseDir = Directory("/storage/emulated/0/Download");
    } else if (Platform.isIOS) {
      baseDir = await getApplicationDocumentsDirectory();
    } else {
      baseDir = (await getDownloadsDirectory())!;
    }

    final voxtaDir = Directory("${baseDir.path}/voxtaDWN");
    if (!await voxtaDir.exists()) {
      await voxtaDir.create(recursive: true);
    }

    final filePath = "${voxtaDir.path}/$fileName";

    Uint8List fileBytes;

    if (keyChat!.isNotEmpty) {
      final decryptedData = decryptBytes(response.bodyBytes, keyChat!);
      final decryptedString = utf8.decode(decryptedData);
      fileBytes = decodeDataUri(decryptedString);
    } else {
      fileBytes = response.bodyBytes;
    }

    final file = File(filePath);
    await file.writeAsBytes(fileBytes);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Файл збережено в папці voxtaDWN"),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    print(e);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Помилка завантаження: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Uint8List decodeDataUri(String dataUri) {
  final prefix = 'base64,';
  final index = dataUri.indexOf(prefix);

  if (index == -1) {
    throw Exception("Invalid Data URI format");
  }

  final base64Part = dataUri.substring(index + prefix.length);
  return base64Decode(base64Part);
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
