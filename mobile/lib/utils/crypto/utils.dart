import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../../../../../../../services/chat/socket_service.dart';

Future<String> getServerPublicKey() async {
  final response = await http.get(
    Uri.parse('${Config.URL_SERVICES_CRYPTO}/public_key_mobile'),
  );

  if (response.statusCode != 200) {
    throw Exception('Не вдалося отримати публічний ключ з сервера');
  }

  try {
    final decoded = jsonDecode(response.body);

    final data = decoded is String ? jsonDecode(decoded) : decoded;

    if (data is Map<String, dynamic> && data.containsKey('key')) {
      return data['key'];
    }

    return response.body;
  } catch (e) {
    return response.body;
  }
}

void getServerIoPublicKey({
  required Function(Map<String, dynamic>) onSuccess,
  required Function(String error) onError,
}) {
  try {
    socket!.emit('get_pub_key', {});

    socket!.off('get_pub_key_return');

    socket!.on('get_pub_key_return', (data) {
      try {
        if (data['code'] == 1) {
          onSuccess(data['key']);
        } else {
          onError('Помилка отримання даних користувачів');
        }
        
      } catch (e) {
        onError('Помилка обробки даних чату');
        socket!.off('get_pub_key_return');
      }
    });
  } catch (e) {
    print('Помилка відправлення запиту: $e');
  }
}
