import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000';

  static Future<Map<String, dynamic>?> getInfoToJwt({
    required String jwtToken,
    required String userId,
  }) async {
    final url = Uri.parse('$baseUrl/get_info_to_jwt');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jwt_token': jwtToken,
          'id': userId,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'good') {
          return responseData;
        } else {
          throw Exception('Сервер відповів: ${responseData['error']}');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Помилка запиту: $e');
      return null;
    }
  }
}
