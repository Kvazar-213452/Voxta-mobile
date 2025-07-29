import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config.dart';

Future<String> getServerPublicKey() async {
  final response = await http.get(
    Uri.parse('${Config.URL_SERVICES_AUNTIFICATION}/public_key_mobile'),
  );
  
  if (response.statusCode != 200) {
    throw Exception('Не вдалося отримати публічний ключ з сервера');
  }

  final body = jsonDecode(response.body);
  return body["key"];
}
