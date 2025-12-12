import 'package:http/http.dart' as http;
import 'dart:convert';

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
    final url = Uri.parse('http://localhost:3004/upload_file_base64');

    final body = json.encode({'file': base64Data, 'name': fileName});

    print('Uploading file via base64: $fileName');
    print('Base64 data length: ${base64Data.length}');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print('Server response status: ${response.statusCode}');
    print('Server response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final jsonResponse = json.decode(response.body);
        final fileUrl = jsonResponse['url'];

        if (fileUrl != null && fileUrl.isNotEmpty) {
          print('File uploaded successfully!');
          print('URL: $fileUrl');
          return fileUrl;
        } else {
          print('File URL is null or empty');
          return null;
        }
      } catch (e) {
        print('Error parsing JSON response: $e');
        print('Response body: ${response.body}');
        return null;
      }
    } else {
      print('Upload failed with status: ${response.statusCode}');
      print('Response: ${response.body}');
      return null;
    }
  } catch (e) {
    print('Error uploading file: $e');
    return null;
  }
}
