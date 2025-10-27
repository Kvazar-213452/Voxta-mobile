import '../../../../../../../services/chat/socket_service.dart';
import 'dart:async';
import 'dart:convert';
import '../../../../../../../utils/crypto/crypto_auto.dart';

void getChat({
  required String idChat,
  required Function(Map<String, dynamic>) onSuccess,
  required Function(String error) onError,
}) {
  try {
    socket!.emit('get_info_chat_fix', {
      'chatId': idChat
    });

    socket!.off('get_info_chat_fix_return');

    socket!.on('get_info_chat_fix_return', (data) {
      try {
        if (data['code'] == 1 && data['chat'] != null) {
          onSuccess(data['chat']);
        } else {
          onError('Помилка отримання даних користувачів');
        }
        
      } catch (e) {
        onError('Помилка обробки даних чату');
        socket!.off('get_info_chat_fix_return');
      }
    });
  } catch (e) {
    print('Помилка відправлення запиту: $e');
  }
}