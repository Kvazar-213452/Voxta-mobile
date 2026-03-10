import 'crypto_app.dart';
import 'utils.dart';
import '../../models/storage_key.dart';
import 'dart:convert';
import 'dart:async';
import '../../utils/crypto/make_key_chat.dart';
import 'crypto_alise.dart';
import 'crypto_chacha20.dart';

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
  String chatId, {
  String? encryptionType,
}) async {
  final completer = Completer<Map<String, dynamic>>();
  final type = encryptionType ?? data['typeChat'] ?? '';

  if (type == 'hyper') {
    return await encryptWithQuantum(data, chatId);
  }

  if (type == 'strong') {
    return await encryptWithChaCha20(data, chatId);
  }

  getPubKeys(
    idChat: chatId,
    onSuccess: (keys) {
      if (keys.isEmpty) {
        completer.complete(data);
        return;
      }

      try {
        final originalContent = data['message']['content'] as String;
        final encryptedContents = <String, String>{};

        keys.forEach((userId, pubKey) {
          try {
            if (pubKey == null || pubKey.toString().trim().isEmpty) {
              return;
            }

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
          completer.complete(data);
          return;
        }

        final encryptedData = Map<String, dynamic>.from(data);
        encryptedData['message'] = Map<String, dynamic>.from(data['message']);
        encryptedData['message']['content'] = encryptedContents;
        encryptedData['message']['encrypted'] = 'RSA-2048';

        completer.complete(encryptedData);
      } catch (e, stackTrace) {
        print('Encryption process failed: $e');
        print('Stack trace: $stackTrace');
        completer.complete(data);
      }
    },
    onError: (error) {
      print('Failed to get public keys: $error');
      print('Returning original data due to error');
      completer.complete(data);
    },
  );

  return completer.future;
}
