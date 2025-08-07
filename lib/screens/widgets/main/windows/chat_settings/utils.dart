import '../../../../../services/chat/socket_service.dart';

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
