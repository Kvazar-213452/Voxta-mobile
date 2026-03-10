import 'utils.dart';
import 'dart:convert';
import 'dart:async';
import '../../utils/crypto/make_key_chat.dart';
import '../../models/storage_chat_key.dart';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

Future<Map<String, dynamic>> encryptWithQuantum(
  Map<String, dynamic> data,
  String chatId,
) async {
  final completer = Completer<Map<String, dynamic>>();

  getPubKeys(
    idChat: chatId,
    onSuccess: (keys) async {
      if (keys.isEmpty) {
        completer.complete(data);
        return;
      }

      try {
        final originalContent = data['message']['content'];
        final contentString = originalContent is String 
            ? originalContent 
            : jsonEncode(originalContent);

        final encryptedContents = <String, Map<String, dynamic>>{};

        for (var entry in keys.entries) {
          final userId = entry.key;
          final pubKey = entry.value;

          try {
            if (pubKey == null || pubKey.toString().trim().isEmpty) {
              continue;
            }

            final cleanedKey = pubKey.toString().trim();

            final quantumEncrypted = await quantumEncrypt(contentString);
            
            final encryptedKey = RSACrypto.encrypt(
              quantumEncrypted['key']!,
              cleanedKey,
            );

            encryptedContents[userId.toString()] = {
              'key': encryptedKey,
              'data': quantumEncrypted['data']!,
            };

          } catch (e, stackTrace) {
            print('Failed to quantum encrypt for user $userId: $e');
            print('Stack trace: $stackTrace');
          }
        }

        if (encryptedContents.isEmpty) {
          completer.complete(data);
          return;
        }

        final encryptedData = Map<String, dynamic>.from(data);
        encryptedData['message'] = Map<String, dynamic>.from(data['message']);
        encryptedData['message']['content'] = encryptedContents;
        encryptedData['message']['encrypted'] = 'QUANTUM-AES-256';

        completer.complete(encryptedData);
      } catch (e, stackTrace) {
        print('Quantum encryption process failed: $e');
        print('Stack trace: $stackTrace');
        completer.complete(data);
      }
    },
    onError: (error) {
      print('Failed to get public keys for quantum encryption: $error');
      completer.complete(data);
    },
  );

  return completer.future;
}

Future<Map<String, String>> quantumEncrypt(String data) async {
  try {
    final quantumKey = _generateQuantumKey(32);

    final encryptedData = await _encryptWithAES256GCM(data, quantumKey);
    
    return {
      'key': base64Encode(quantumKey),
      'data': encryptedData,
    };
  } catch (e) {
    print('Quantum encryption error: $e');
    rethrow;
  }
}

List<int> _generateQuantumKey(int length) {
  final random = Random.secure();
  return List<int>.generate(length, (_) => random.nextInt(256));
}

Future<String> _encryptWithAES256GCM(String data, List<int> key) async {
  try {
    final keyBytes = Uint8List.fromList(key);
    final iv = _generateQuantumKey(16);
    
    final encrypter = Encrypter(AES(
      Key(keyBytes),
      mode: AESMode.gcm,
    ));
    
    final encrypted = encrypter.encrypt(
      data,
      iv: IV(Uint8List.fromList(iv)),
    );
    
    final combined = {
      'iv': base64Encode(iv),
      'data': encrypted.base64,
    };
    
    return jsonEncode(combined);
  } catch (e) {
    print('AES-256-GCM encryption error: $e');
    rethrow;
  }
}

Future<String> _quantumDecrypt(String encryptedData, String encryptedKey, String privateKey) async {
  try {
    final quantumKey = RSACrypto.decrypt(encryptedKey, privateKey);
    final keyBytes = base64Decode(quantumKey);
    
    final combined = jsonDecode(encryptedData) as Map<String, dynamic>;
    final iv = base64Decode(combined['iv'] as String);
    final data = combined['data'] as String;

    final encrypter = Encrypter(AES(
      Key(Uint8List.fromList(keyBytes)),
      mode: AESMode.gcm,
    ));
    
    final decrypted = encrypter.decrypt64(
      data,
      iv: IV(Uint8List.fromList(iv)),
    );
    
    return decrypted;
  } catch (e) {
    print('Quantum decryption error: $e');
    rethrow;
  }
}

Future<Map<String, dynamic>> decryptQuantumMessage(
  Map<String, dynamic> messageData,
  String userId,
) async {
  try {
    final content = messageData['content'];
    
    if (content is! Map) {
      return messageData;
    }

    final userContent = content[userId];
    
    if (userContent == null || userContent is! Map) {
      print('No quantum encrypted content for user $userId');
      return messageData;
    }

    final encryptedKey = userContent['key'] as String;
    final encryptedData = userContent['data'] as String;
    
    final privateKey = await ChatKeysDB.getPrivateKey(messageData['chatId']);
    
    if (privateKey == null || privateKey.isEmpty) {
      return messageData;
    }

    final decryptedContent = await _quantumDecrypt(
      encryptedData,
      encryptedKey,
      privateKey,
    );

    final decryptedData = Map<String, dynamic>.from(messageData);
    decryptedData['content'] = decryptedContent;
    
    return decryptedData;
  } catch (e, stackTrace) {
    print('Failed to decrypt quantum message: $e');
    print('Stack trace: $stackTrace');
    return messageData;
  }
}
