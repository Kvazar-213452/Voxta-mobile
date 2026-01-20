import 'crypto_app.dart';
import 'utils.dart';
import '../../models/storage_key.dart';
import 'dart:convert';
import 'dart:async';
import '../../../../../../../services/chat/socket_service.dart';
import '../../utils/crypto/make_key_chat.dart';

Future<Map<String, dynamic>> decrypted_auto(Map<String, dynamic> data) async {
  final keyPair = await getOrCreateKeyPair();

  final jsonResponse = data;
  final decrypted = await decryptServerResponse(
    jsonResponse,
    keyPair.privateKey,
  );

  return jsonDecode(decrypted);
}

Future<Map<String, dynamic>> encrypt_auto(Map<String, dynamic> data) async {
  final keyPair = await getOrCreateKeyPair();
  final publicKeyPem = encodePublicKeyToPemPKCS1(keyPair.publicKey);

  final dataToEncrypt = jsonEncode(data);

  final serverPublicKeyPem = await getServerPublicKey();
  final encrypted = await encryptMessage(dataToEncrypt, serverPublicKeyPem);

  return {
    'data': {'data': encrypted['data'], 'key': encrypted['key']},
    'key': publicKeyPem,
    'type': 'mobile',
  };
}

Future<Map<String, dynamic>> encryptAutoServer(
  Map<String, dynamic> data,
) async {
  final keyPair = await getOrCreateKeyPair();
  final publicKeyPem = encodePublicKeyToPemPKCS1(keyPair.publicKey);

  final dataToEncrypt = jsonEncode(data);

  final completer = Completer<Map<String, dynamic>>();

  getServerIoPublicKey(
    onSuccess: (key) async {
      final encrypted = await encryptMessage(dataToEncrypt, key);

      completer.complete({
        'data': {'data': encrypted['data'], 'key': encrypted['key']},
        'key': publicKeyPem,
        'type': 'mobile',
      });
    },
  );

  return completer.future;
}

Future<Map<String, dynamic>> encryptAutoToUsers(
  Map<String, dynamic> data,
  String chatId,
) async {
  final completer = Completer<Map<String, dynamic>>();

  getPubKeys(
    idChat: chatId,
    onSuccess: (keys) {
      try {
        final originalContent = data['message']['content'] as String;
        
        final encryptedContents = <String, String>{};
        
        keys.forEach((userId, pubKey) {
          try {
            final cleanedKey = pubKey.toString().trim();
            
            final encryptedContent = RSACrypto.encrypt(
              originalContent,
              cleanedKey,
            );
            encryptedContents[userId.toString()] = encryptedContent;
          } catch (e, stackTrace) {
            print('Failed to encrypt for user $userId: $e');
            print('Stack trace: $stackTrace');
          }
        });
        
        if (encryptedContents.isEmpty) {
          throw Exception('Failed to encrypt for any user');
        }
        
        final encryptedData = Map<String, dynamic>.from(data);
        encryptedData['message'] = Map<String, dynamic>.from(data['message']);
        encryptedData['message']['content'] = encryptedContents;
        
        completer.complete(encryptedData);
      } catch (e, stackTrace) {
        print('Encryption process failed: $e');
        print('Stack trace: $stackTrace');
        completer.completeError('Encryption failed: $e');
      }
    },
    onError: (error) {
      print('Failed to get public keys: $error');
      completer.completeError(error);
    },
  );

  return completer.future;
}

void getPubKeys({
  required String idChat,
  required Function(Map<String, dynamic>) onSuccess,
  required Function(String error) onError,
}) {
  try {
    socket!.emit('get_pub_keys_chat', {'chatId': idChat});

    socket!.off('get_pub_keys_chat_return');

    socket!.on('get_pub_keys_chat_return', (data) {
      try {
          onSuccess(data['keys']);
      } catch (e) {
        onError('Помилка обробки даних чату');
        socket!.off('get_pub_keys_chat_return');
      }
    });
  } catch (e) {
    print('Помилка відправлення запиту: $e');
  }
}
