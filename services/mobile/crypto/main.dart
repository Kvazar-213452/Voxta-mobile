import 'src/encryption_server.dart';

void main() async {
  final encryptionServer = EncryptionServer();
  encryptionServer.generateKey();
  await encryptionServer.startServer();
}