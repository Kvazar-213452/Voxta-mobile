import 'utils.dart';
import 'dart:convert';
import 'dart:async';
import '../../utils/crypto/make_key_chat.dart';
import '../../models/storage_chat_key.dart';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

Future<Map<String, dynamic>> encryptWithChaCha20(
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
            final chachaEncrypted = await chaCha20Encrypt(contentString);
            
            final encryptedKey = RSACrypto.encrypt(
              chachaEncrypted['key']!,
              cleanedKey,
            );

            encryptedContents[userId.toString()] = {
              'key': encryptedKey,
              'data': chachaEncrypted['data']!,
            };

          } catch (e, stackTrace) {
            print('Failed to ChaCha20 encrypt for user $userId: $e');
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
        encryptedData['message']['encrypted'] = 'ChaCha20-Poly1305';

        completer.complete(encryptedData);
      } catch (e, stackTrace) {
        print('ChaCha20 encryption process failed: $e');
        print('Stack trace: $stackTrace');
        completer.complete(data);
      }
    },
    onError: (error) {
      print('Failed to get public keys for ChaCha20 encryption: $error');
      completer.complete(data);
    },
  );

  return completer.future;
}

Future<Map<String, String>> chaCha20Encrypt(String data) async {
  try {
    final key = _generateSecureKey(32);
    final encryptedData = await _encryptWithChaCha20Poly1305(data, key);
    
    return {
      'key': base64Encode(key),
      'data': encryptedData,
    };
  } catch (e) {
    print('ChaCha20 encryption error: $e');
    rethrow;
  }
}

List<int> _generateSecureKey(int length) {
  final random = Random.secure();
  return List<int>.generate(length, (_) => random.nextInt(256));
}

Future<String> _encryptWithChaCha20Poly1305(String data, List<int> key) async {
  try {
    final keyBytes = Uint8List.fromList(key);
    final nonce = Uint8List.fromList(_generateSecureKey(8));
    
    final cipher = ChaCha20Engine();
    final params = ParametersWithIV(KeyParameter(keyBytes), nonce);
    cipher.init(true, params);

    final dataBytes = Uint8List.fromList(utf8.encode(data));

    final encrypted = Uint8List(dataBytes.length);
    for (var i = 0; i < dataBytes.length; i++) {
      encrypted[i] = cipher.returnByte(dataBytes[i]);
    }
    
    final combined = {
      'nonce': base64Encode(nonce),
      'data': base64Encode(encrypted),
    };
    
    return jsonEncode(combined);
  } catch (e) {
    print('ChaCha20 encryption error: $e');
    rethrow;
  }
}

Future<String> _chaCha20Decrypt(
  String encryptedData, 
  String encryptedKey, 
  String privateKey,
) async {
  try {
    final chachaKey = RSACrypto.decrypt(encryptedKey, privateKey);
    final keyBytes = Uint8List.fromList(base64Decode(chachaKey));
    
    final combined = jsonDecode(encryptedData) as Map<String, dynamic>;
    final nonce = Uint8List.fromList(base64Decode(combined['nonce'] as String));
    final encryptedBytes = Uint8List.fromList(base64Decode(combined['data'] as String));

    final cipher = ChaCha20Engine();
    final params = ParametersWithIV(KeyParameter(keyBytes), nonce);
    cipher.init(false, params);
    
    final decrypted = Uint8List(encryptedBytes.length);
    for (var i = 0; i < encryptedBytes.length; i++) {
      decrypted[i] = cipher.returnByte(encryptedBytes[i]);
    }
    
    return utf8.decode(decrypted);
  } catch (e) {
    print('ChaCha20 decryption error: $e');
    rethrow;
  }
}

Future<Map<String, dynamic>> decryptChaCha20Message(
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
      print('No ChaCha20 encrypted content for user $userId');
      return messageData;
    }

    final encryptedKey = userContent['key'] as String;
    final encryptedData = userContent['data'] as String;
    
    final privateKey = await ChatKeysDB.getPrivateKey(messageData['chatId']);
    
    if (privateKey == null || privateKey.isEmpty) {
      print('Private key not found for ChaCha20 decryption');
      return messageData;
    }

    final decryptedContent = await _chaCha20Decrypt(
      encryptedData,
      encryptedKey,
      privateKey,
    );

    final decryptedData = Map<String, dynamic>.from(messageData);
    decryptedData['content'] = decryptedContent;
    
    return decryptedData;
  } catch (e, stackTrace) {
    print('Failed to decrypt ChaCha20 message: $e');
    print('Stack trace: $stackTrace');
    return messageData;
  }
}
