import '../../../../../services/chat/socket_service.dart';
import '../../../../../utils/crypto/crypto_auto.dart';

void delMsg(String idMsg, String idChat) async {
  socket!.emit('del_msg', await encrypt_auto({'idMsg': idMsg, 'idChat': idChat}));
}
