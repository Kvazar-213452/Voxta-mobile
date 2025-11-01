import '../../../../../../../services/chat/socket_service.dart';

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

void delChat({
  required String idChat,
  required Function() onSuccess,
  required Function(String error) onError,
}) {
  try {
    socket!.emit('del_chat', {
      'chatId': idChat
    });

    socket!.off('del_chat_return');

    socket!.on('del_chat_return', (data) async {
      try {
        if (data['code'] == 1) {
          await loadChats();
          onSuccess();
        } else {
          onError('Помилка отримання даних користувачів');
        }
        
      } catch (e) {
        onError('Помилка обробки даних чату');
        socket!.off('del_chat_return');
      }
    });
  } catch (e) {
    print('Помилка відправлення запиту: $e');
  }
}