import '../../../../../services/chat/socket_service.dart';
import 'dart:async';
import 'dart:convert';
import '../../../../../utils/crypto/crypto_auto.dart';

Future<Map<String, dynamic>> getSelf() async {
  final completer = Completer<Map<String, dynamic>>();
  Timer? timeoutTimer;

  try {
    // Перевіряємо чи є з'єднання з сокетом
    if (socket == null || !socket!.connected) {
      completer.completeError('Немає з\'єднання з сервером');
      return completer.future;
    }

    // Додаємо таймаут на 10 секунд
    timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        socket!.off('get_info_self');
        completer.completeError('Час очікування відповіді від сервера минув');
      }
    });

    // Видаляємо попередні слухачі
    socket!.off('get_info_self');

    // Додаємо новий слухач
    socket!.on('get_info_self', (data) async {
      try {
        // Перевіряємо чи completer вже завершений
        if (completer.isCompleted) {
          return;
        }

        timeoutTimer?.cancel();
        socket!.off('get_info_self');

        // Розшифровуємо дані
        final decryptedData = await decrypted_auto(data);

        if (decryptedData['code'] == 1) {
          // Перевіряємо структуру даних користувача
          final userData = decryptedData['user'];
          if (userData != null) {
            // Повертаємо Map безпосередньо
            if (userData is Map<String, dynamic>) {
              completer.complete(userData);
            } else if (userData is String) {
              // Якщо це JSON строка, парсимо її
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

    // Шифруємо та відправляємо запит
    final encryptedRequest = await encrypt_auto({'type': 'profile'});
    socket!.emit('get_info_self', encryptedRequest);

  } catch (e) {
    timeoutTimer?.cancel();
    if (!completer.isCompleted) {
      socket!.off('get_info_self');
      
      // Обробляємо специфічні помилки шифрування
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

// Альтернативна функція з retry механізмом
Future<Map<String, dynamic>> getSelfWithRetry({int maxRetries = 3}) async {
  Exception? lastException;
  
  for (int attempt = 0; attempt < maxRetries; attempt++) {
    try {
      // Затримка перед повторною спробою
      if (attempt > 0) {
        await Future.delayed(Duration(seconds: attempt * 2));
      }
      
      return await getSelf();
    } catch (e) {
      lastException = e is Exception ? e : Exception(e.toString());
      
      // Якщо це остання спроба, кидаємо помилку
      if (attempt == maxRetries - 1) {
        throw lastException;
      }
      
      // Логування спроби
      print('Спроба ${attempt + 1} не вдалася: $e');
    }
  }
  
  throw lastException ?? Exception('Невідома помилка');
}