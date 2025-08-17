import '../../../../../services/chat/socket_service.dart';
import 'dart:async';
import 'dart:convert';
import '../../../../../utils/crypto/crypto_auto.dart';

Future<Map<String, dynamic>> getSelf() async {
  final completer = Completer<Map<String, dynamic>>();
  Timer? timeoutTimer;

  try {
    if (socket == null || !socket!.connected) {
      completer.completeError('Немає з\'єднання з сервером');
      return completer.future;
    }

    timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        socket!.off('get_info_self');
        completer.completeError('Час очікування відповіді від сервера минув');
      }
    });

    socket!.off('get_info_self');

    socket!.on('get_info_self', (data) async {
      try {
        if (completer.isCompleted) {
          return;
        }

        timeoutTimer?.cancel();
        socket!.off('get_info_self');

        final decryptedData = await decrypted_auto(data);

        if (decryptedData['code'] == 1) {
          final userData = decryptedData['user'];
          if (userData != null) {
            if (userData is Map<String, dynamic>) {
              completer.complete(userData);
            } else if (userData is String) {
              try {
                final parsedData = jsonDecode(userData);
                completer.complete(parsedData is Map<String, dynamic> ? parsedData : {});
              } catch (e) {
                completer.completeError('Помилка парсингу JSON: $e');
              }
            } else {
              completer.completeError('Невірний формат даних користувача');
            }
          } else {
            completer.completeError('Отримано пусті дані користувача');
          }
        } else {
          final errorMessage = decryptedData['message'] ?? 'Помилка отримання даних користувача';
          completer.completeError(errorMessage);
        }
      } catch (e) {
        if (!completer.isCompleted) {
          socket!.off('get_info_self');
          completer.completeError('Помилка обробки даних: $e');
        }
      }
    });

    final encryptedRequest = await encrypt_auto({'type': 'profile'});
    socket!.emit('get_info_self', encryptedRequest);

  } catch (e) {
    timeoutTimer?.cancel();
    if (!completer.isCompleted) {
      socket!.off('get_info_self');
      
      if (e.toString().contains('CryptUnprotectData') || 
          e.toString().contains('flutter_secure_storage')) {
        completer.completeError('Помилка системи безпеки. Спробуйте перезапустити додаток');
      } else {
        completer.completeError('Помилка відправлення запиту: $e');
      }
    }
  }

  return completer.future;
}

Future<Map<String, dynamic>> getSelfWithRetry({int maxRetries = 3}) async {
  Exception? lastException;
  
  for (int attempt = 0; attempt < maxRetries; attempt++) {
    try {
      if (attempt > 0) {
        await Future.delayed(Duration(seconds: attempt * 2));
      }
      
      return await getSelf();
    } catch (e) {
      lastException = e is Exception ? e : Exception(e.toString());
      
      if (attempt == maxRetries - 1) {
        throw lastException;
      }
      
      print('Спроба ${attempt + 1} не вдалася: $e');
    }
  }
  
  throw lastException ?? Exception('Невідома помилка');
}
