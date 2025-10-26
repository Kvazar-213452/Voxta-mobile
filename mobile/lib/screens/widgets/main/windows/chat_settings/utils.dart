import '../../../../../services/chat/socket_service.dart';
import 'dart:async';
import '../../../../../utils/crypto/crypto_auto.dart';

// ! ============ server func ============
void getInfoUsers({
  required String type,
  required List<dynamic> users,
  required Function(Map<String, dynamic>) onSuccess,
  required Function(String error) onError,
}) {
  try {
    socket!.emit('get_info_users', {
      'server': null,
      'type': type,
      'users': users
    });

    socket!.off('get_info_users_return');

    socket!.on('get_info_users_return', (data) {
      try {
        if (data['code'] == 1 && data['users'] != null) {
          onSuccess(data['users']);
        } else {
          onError('Помилка отримання даних користувачів');
        }
        
      } catch (e) {
        onError('Помилка обробки даних чату');
        socket!.off('get_info_users_return');
      }
    });
  } catch (e) {
    print('Помилка відправлення запиту: $e');
  }
}

void saveSettingsChat(String id, String type, Map<String, dynamic> dataChat) {
  socket!.emit('save_settings_chat', {
    'dataChat': dataChat,
    'id': id,
    'typeChat': type
  });
}

void delUserInChat(String id, String type, String userId) {
  socket!.emit('del_user_in_chat', {
    'userId': userId,
    'id': id,
    'typeChat': type
  });
}

Future<String> getKeyChat(String id) async {
  final completer = Completer<String>();

  try {
    socket!.emit('get_key_chat', { 'id': id });

    socket!.off('get_key_chat');

    socket!.on('get_key_chat', (data) {
      try {
        if (data['code'] == 1) {
          completer.complete(data['key']);
        } else {
          completer.completeError('Помилка отримання даних користувачів');
        }
      } catch (e) {
        completer.completeError('Помилка обробки даних чату');
        socket!.off('get_key_chat');
      }
    });
  } catch (e) {
    completer.completeError('Помилка відправлення запиту: $e');
  }

  return completer.future;
}

void getInfoChat({
  required String id,
  required String type,
  required Function(String name, String description, Map<String, dynamic> data) onSuccess,
  required Function(String error) onError,
}) {
  try {
    socket!.emit('get_info_chat', {
      'chatId': id,
      'typeChat': type,
      'type': "main",
    });

    socket!.off('chat_info');

    socket!.on('chat_info', (data) {
      try {
        final String name = data['chat']['name'] ?? 'Невідомий чат';
        final String description = data['chat']['desc'] ?? '';
        
        onSuccess(name, description, data['chat'] as Map<String, dynamic>);
        
      } catch (e) {
        print('Помилка парсингу даних чату: $e');
        onError('Помилка обробки даних чату');
        socket!.off('chat_info');
      }
    });
  } catch (e) {
    print('Помилка відправлення запиту: $e');
  }
}

Future<String> generateRandomCode(String id) async {
  final completer = Completer<String>();

  try {
    socket!.emit('generate_key_chat', {
      'id': id
    });

    socket!.off('generate_key_chat');

    socket!.on('generate_key_chat', (data) {
      try {
        if (data['code'] == 1) {
          completer.complete(data['key']);
        } else {
          completer.completeError('Помилка отримання даних користувачів');
        }
      } catch (e) {
        completer.completeError('Помилка обробки даних чату');
        socket!.off('generate_key_chat');
      }
    });
  } catch (e) {
    completer.completeError('Помилка відправлення запиту: $e');
  }

  return completer.future;
}

Future<void> delSelfInChat(String id, String type) async {
  socket!.emit('del_user_in_chat_self', await encrypt_auto({'id': id, 'typeChat': type}));
}
