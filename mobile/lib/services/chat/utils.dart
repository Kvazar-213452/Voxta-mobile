import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';

String formatTime(String createdAt) {
  try {
    DateTime dateTime = DateTime.parse(createdAt);
    DateTime now = DateTime.now();

    if (dateTime.day == now.day &&
        dateTime.month == now.month &&
        dateTime.year == now.year) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}';
    }
  } catch (e) {
    return 'Невідомо';
  }
}

Future<String?> uploadLargeFileBase64(
  String base64Data,
  String fileName,
) async {
  try {
    final url = Uri.parse(Config.URL_SERVICES_DATA + '/upload_file_base64');

    final body = json.encode({'file': base64Data, 'name': fileName});

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      try {
        final jsonResponse = json.decode(response.body);
        final fileUrl = jsonResponse['url'];

        if (fileUrl != null && fileUrl.isNotEmpty) {
          return fileUrl;
        } else {
          print('File URL is null or empty');
          return null;
        }
      } catch (e) {
        print('Error parsing JSON response: $e');
        return null;
      }
    } else {
      print('Upload failed with status: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error uploading file: $e');
    return null;
  }
}
