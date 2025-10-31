import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config.dart';

Future<String> getServerPublicKey() async {
  final response = await http.get(
    Uri.parse('${Config.URL_SERVICES_CRYPTO}/public_key_mobile'),
  );

  if (response.statusCode != 200) {
    throw Exception('Не вдалося отримати публічний ключ з сервера');
  }

  try {
    // Спробуємо розпарсити JSON
    final decoded = jsonDecode(response.body);

    // Якщо це ще один JSON усередині (рядок з лапками)
    final data = decoded is String ? jsonDecode(decoded) : decoded;

    // Якщо це Map ({"key": "-----BEGIN..."})
    if (data is Map<String, dynamic> && data.containsKey('key')) {
      return data['key'];
    }

    // Якщо формат неочікуваний — повертаємо як текст
    return response.body;
  } catch (e) {
    // Якщо це не JSON — просто повертаємо текст ключа
    return response.body;
  }
}
