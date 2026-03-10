import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/export.dart';
import '../../models/storage_chat_key.dart';
import '../../utils/crypto/make_key_chat.dart';
import 'package:encrypt/encrypt.dart';

String generateKey() {
  final random = Random.secure();
  final values = List<int>.generate(32, (_) => random.nextInt(256));
  return base64Encode(values);
}

String encryptText(String plainText, String base64Key) {
  final key = encrypt.Key(base64Url.decode(base64Key));

  final iv = encrypt.IV.fromSecureRandom(16);
  final encrypter = encrypt.Encrypter(encrypt.AES(key));

  final encrypted = encrypter.encrypt(plainText, iv: iv);

  final combined = iv.bytes + encrypted.bytes;
  return base64Encode(combined);
}

String decryptText(String encryptedText, String base64Key) {
  final key = encrypt.Key(base64Url.decode(base64Key));
  final combined = base64Decode(encryptedText);

  final iv = encrypt.IV(combined.sublist(0, 16));
  final encryptedBytes = combined.sublist(16);

  final encrypter = encrypt.Encrypter(encrypt.AES(key));
  final decrypted = encrypter.decrypt(
    encrypt.Encrypted(encryptedBytes),
    iv: iv,
  );

  return decrypted;
}

Uint8List decryptBytes(Uint8List encryptedBytes, String base64Key) {
  final key = encrypt.Key(base64Decode(base64Key));

  if (encryptedBytes.length > 20) {
    final snippet = String.fromCharCodes(encryptedBytes.sublist(0, 20));
    if (snippet.startsWith('data:')) {
      final commaIndex = snippet.indexOf('base64,');
      if (commaIndex == -1) throw Exception("Invalid data URI format");

      final content = utf8.decode(encryptedBytes);
      final pureBase64 = content.substring(content.indexOf('base64,') + 7);
      encryptedBytes = base64Decode(pureBase64);
    }
  }

  if (encryptedBytes.length < 17) {
    throw Exception("Encrypted data is corrupted");
  }

  final iv = encrypt.IV(encryptedBytes.sublist(0, 16));
  final cipherBytes = encryptedBytes.sublist(16);

  final encrypter = encrypt.Encrypter(encrypt.AES(key));

  final decrypted = encrypter.decryptBytes(
    encrypt.Encrypted(cipherBytes),
    iv: iv,
  );

  return Uint8List.fromList(decrypted);
}

Future<Map<String, dynamic>> decryptMessages(Map<String, dynamic> data) async {
  final info = await ChatKeysDB.getChatInfo(data["chatId"]);

  if (!info?["isEncrypted"]) {
    return data;
  }

  final messages = data["messages"];
  if (messages is! List) {
    return data;
  }

  for (int idx = 0; idx < messages.length; idx++) {
    final message = messages[idx];
    if (message is! Map<String, dynamic>) continue;


    if (message["type"] == "file") {
      continue;
    }

    final content = message["content"];

    if (content is! String || content.isEmpty) {
      continue;
    }

    final base64Pattern = RegExp(r'^[A-Za-z0-9+/=]+$');
    final looksEncrypted =
        base64Pattern.hasMatch(content) && content.length % 4 == 0;

    if (!looksEncrypted) {
      continue;
    }

    try {
      final decrypted = decryptText(content, info?["keyAES"]);
      message["content"] = decrypted;
      print('Decrypted content: ${decrypted.substring(0, min(50, decrypted.length))}');
    } catch (e, stackTrace) {
      print('✗ Failed to decrypt message ${message["_id"]}: $e');
      print('Stack trace: $stackTrace');
    }
  }

  return data;
}

Future<Map<String, dynamic>> decryptMessage(
  Map<String, dynamic> message,
  String chatId,
) async {
  try {
    final info = await ChatKeysDB.getChatInfo(chatId);

    if (!info?["isEncrypted"]) {
      return message;
    }

    final content = message["content"];

    if (content is! String) {
      return message;
    }

    final base64Pattern = RegExp(r'^[A-Za-z0-9+/=]+$');
    final looksEncrypted =
        base64Pattern.hasMatch(content) && content.length % 4 == 0;

    if (looksEncrypted) {
      try {
        final decrypted = decryptText(content, info?["keyAES"]);
        message["content"] = decrypted;
      } catch (e, stackTrace) {
        print('✗ Decryption failed: $e');
        print('Stack trace: $stackTrace');
      }
    }

    return message;
  } catch (e, stackTrace) {
    print('✗ Error in decryptMessage: $e');
    print('Stack trace: $stackTrace');
    return message;
  }
}

Future<Map<String, dynamic>> decryptMessagesEndToEnd(
  Map<String, dynamic> data,
  String userIdMy,
) async {
  final result = Map<String, dynamic>.from(data);

  if (!result.containsKey("messages")) {
    return result;
  }

  final List messages = List.from(result["messages"]);
  final List newMessages = [];

  for (int idx = 0; idx < messages.length; idx++) {
    var msg = messages[idx];
    final message = Map<String, dynamic>.from(msg);
    final content = message["content"];
    final encryptionType = message["encrypted"] as String?;

    try {
      if (encryptionType == "ChaCha20-Poly1305") {
        if (content is Map) {
          if (content.containsKey(userIdMy)) {
            final userContent = content[userIdMy];
            message["content"] = userContent;
          } else {
            print('✗ No content found for user $userIdMy in ChaCha20 message');
            print('Available users: ${content.keys}');
          }
        } else {
          print('✗ Content is not a Map for ChaCha20 message');
        }
      }

      else if (encryptionType == "QUANTUM-AES-256") {
        if (content is Map) {
          if (content.containsKey(userIdMy)) {
            final userContent = content[userIdMy];
            
            message["content"] = userContent;
          } else {
            print('✗ No content found for user $userIdMy in quantum message');
            print('Available users: ${content.keys}');
          }
        } else {
          print('✗ Content is not a Map for quantum message');
        }
      } else if (encryptionType == "RSA-2048" || content is Map) {
        
        if (content is Map && content.containsKey(userIdMy)) {
          final encrypted = content[userIdMy];
          
          if (encrypted is String && isBase64(encrypted)) {
            message["content"] = encrypted;
          } else {
            print('✗ Encrypted content is not base64 string');
          }
        } else {
          print('Content is not Map or does not contain user $userIdMy');
        }
      } else if (content is String) {
        print('Content is already a String');
        
        if (!isBase64(content)) {
          print('Content is not base64, keeping as is');
          newMessages.add(message);
          continue;
        } else {
          print('Content is base64 string (length: ${content.length})');
        }
      }
    } catch (e, stackTrace) {
      print("✗ Decrypt error for message ${message['_id']}: $e");
      print('Stack trace: $stackTrace');
    }

    newMessages.add(message);
  }

  result["messages"] = newMessages;
  return result;
}

Future<Map<String, dynamic>> decryptMessagesEndToEndFull(
  Map<String, dynamic> data,
  String chatId,
) async {
  if (data['messages'] == null || data['messages'].isEmpty) {
    print('No messages to decrypt');
    return data;
  }

  final Map<String, dynamic> decryptedData = Map<String, dynamic>.from(data);
  final List<dynamic> messages = List<dynamic>.from(data['messages']);

  for (int i = 0; i < messages.length; i++) {
    final message = Map<String, dynamic>.from(messages[i]);
    final content = message['content'];
    final encryptionType = message['encrypted'] as String?;

    try {
      if (encryptionType == "ChaCha20-Poly1305") {
        if (content is Map) {
          if (content.containsKey('key') && content.containsKey('data')) {
            final decrypted = await _decryptChaCha20ContentFull(
              content as Map<String, dynamic>,
              chatId,
            );
            
            if (decrypted.isNotEmpty) {
              message['content'] = decrypted;
              messages[i] = message;
            } else {
              print('✗ ChaCha20 decryption returned empty string');
            }
          } else {
            print('✗ Missing key or data field in ChaCha20 content');
          }
        } else {
          print('✗ Content is not a Map for ChaCha20 message');
        }
      }

      else if (encryptionType == "QUANTUM-AES-256") {
        if (content is Map) {
          if (content.containsKey('key') && content.containsKey('data')) {
            final decrypted = await _decryptQuantumContentFull(
              content as Map<String, dynamic>,
              chatId,
            );
            
            if (decrypted.isNotEmpty) {
              message['content'] = decrypted;
              messages[i] = message;
              print('Decrypted content: ${decrypted.substring(0, min(50, decrypted.length))}');
            } else {
              print('✗ Quantum decryption returned empty string');
            }
          } else {
            print('✗ Missing key or data field in quantum content');
          }
        } else {
          print('✗ Content is not a Map for quantum message');
        }
      }
      else if (encryptionType == "RSA-2048" || (content is String && isBase64(content))) {
        final decrypted = await _decryptRSAContent(content, chatId);
        
        if (decrypted != content) {
          message['content'] = decrypted;
          messages[i] = message;
        } else {
          print('✗ RSA decryption failed or returned original content');
        }
      } else {
        print('Unknown encryption type or already decrypted');
      }
    } catch (e, stackTrace) {
      print('✗ Could not decrypt message ${message['_id']}: $e');
      print('Stack trace: $stackTrace');
    }
  }

  decryptedData['messages'] = messages;
  return decryptedData;
}

Future<String> _decryptRSAContent(String encryptedContent, String chatId) async {
  final info = await ChatKeysDB.getChatInfo(chatId);
  final privateKeys = info?["privateKeys"];

  if (privateKeys == null || privateKeys.isEmpty) {
    print('✗ No private keys available for RSA decryption');
    return encryptedContent;
  }

  for (int i = 0; i < privateKeys.length; i++) {
    final privateKey = privateKeys[i];
    
    try {
      final decryptedContent = RSACrypto.decrypt(encryptedContent, privateKey);

      return decryptedContent;
    } catch (e) {
      print('✗ Failed with key $i: $e');
      continue;
    }
  }

  return encryptedContent;
}

Future<String> _decryptChaCha20ContentFull(
  Map<String, dynamic> content,
  String chatId,
) async {
  try {
    final encryptedKey = content['key'] as String?;
    final encryptedData = content['data'] as String?;
    
    if (encryptedKey == null || encryptedData == null) {
      return '';
    }

    final privateKey = await ChatKeysDB.getPrivateKey(chatId);
    
    if (privateKey == null || privateKey.isEmpty) {
      print('✗ Private RSA key not found for ChaCha20 decryption');
      return '';
    }

    final chaCha20KeyBase64 = RSACrypto.decrypt(encryptedKey, privateKey);
    final chaCha20Key = base64Decode(chaCha20KeyBase64);
    
    final decryptedContent = await _chaCha20DecryptWithKey(
      encryptedData,
      chaCha20Key,
    );

    return decryptedContent;
  } catch (e, stackTrace) {
    print('✗ Failed to decrypt ChaCha20 content: $e');
    print('Stack trace: $stackTrace');
    return '';
  }
}

Future<String> _chaCha20DecryptWithKey(
  String encryptedData,
  List<int> chaCha20Key,
) async {
  try {
    final combined = jsonDecode(encryptedData) as Map<String, dynamic>;

    final nonceBase64 = combined['nonce'] as String;
    final dataBase64 = combined['data'] as String;
    
    final nonce = Uint8List.fromList(base64Decode(nonceBase64));
    final encryptedBytes = Uint8List.fromList(base64Decode(dataBase64));

    final cipher = ChaCha20Engine();
    final params = ParametersWithIV(
      KeyParameter(Uint8List.fromList(chaCha20Key)),
      nonce,
    );
    cipher.init(false, params);

    final decrypted = Uint8List(encryptedBytes.length);
    for (var i = 0; i < encryptedBytes.length; i++) {
      decrypted[i] = cipher.returnByte(encryptedBytes[i]);
    }
    
    final result = utf8.decode(decrypted);
    
    return result;
  } catch (e, stackTrace) {
    print('✗ ChaCha20 decryption error: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}

Future<String> _decryptQuantumContentFull(
  Map<String, dynamic> content,
  String chatId,
) async {
  try {
    final encryptedKey = content['key'] as String?;
    final encryptedData = content['data'] as String?;
    
    if (encryptedKey == null || encryptedData == null) {
      return '';
    }

    final privateKey = await ChatKeysDB.getPrivateKey(chatId);
    
    if (privateKey == null || privateKey.isEmpty) {
      print('✗ Private RSA key not found for quantum decryption');
      return '';
    }

    final quantumKeyBase64 = RSACrypto.decrypt(encryptedKey, privateKey);
    final quantumKey = base64Decode(quantumKeyBase64);

    final decryptedContent = await _quantumDecryptWithKey(
      encryptedData,
      quantumKey,
    );

    return decryptedContent;
  } catch (e, stackTrace) {
    print('✗ Failed to decrypt quantum content: $e');
    print('Stack trace: $stackTrace');
    return '';
  }
}

String _oneTimePadDecrypt(String encryptedBase64, List<int> key) {
  try {
    final encrypted = base64Decode(encryptedBase64);
    
    final decrypted = List<int>.generate(
      encrypted.length,
      (i) => encrypted[i] ^ key[i % key.length],
    );
    
    final result = utf8.decode(decrypted);
    return result;
  } catch (e, stackTrace) {
    print('✗ OTP decryption error: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}

Future<String> _aesGcmDecrypt(
  Map<String, dynamic> combined,
  List<int> quantumKey,
) async {
  try {
    final ivBase64 = combined['iv'] as String;
    final dataBase64 = combined['data'] as String;
    
    final iv = base64Decode(ivBase64);
    
    final encrypter = Encrypter(AES(
      Key(Uint8List.fromList(quantumKey)),
      mode: AESMode.gcm,
    ));
    
    final decrypted = encrypter.decrypt64(
      dataBase64,
      iv: IV(Uint8List.fromList(iv)),
    );
    
    return decrypted;
  } catch (e, stackTrace) {
    print('✗ AES-GCM decryption error: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}

bool isBase64(String str) {
  try {
    base64Decode(str);
    return true;
  } catch (e) {
    return false;
  }
}

Map<String, dynamic> decryptMessageEndToEnd(
  Map<String, dynamic> message,
  String userIdMy,
) {
  final result = Map<String, dynamic>.from(message);

  if (!result.containsKey("content")) {
    return result;
  }

  final content = result["content"];
  final encryptionType = result["encrypted"] as String?;

  if (encryptionType == "ChaCha20-Poly1305") {
    if (content is Map && content.containsKey(userIdMy)) {
      result["content"] = content[userIdMy];
    } else {
      print('✗ Content is not Map or missing user data');
    }
  } else if (encryptionType == "QUANTUM-AES-256") {
    if (content is Map && content.containsKey(userIdMy)) {
      result["content"] = content[userIdMy];
      print('✓ Extracted quantum content for user');
    } else {
      print('✗ Content is not Map or missing user data');
    }
  } else if (content is Map) {
    if (content.containsKey(userIdMy)) {
      final encrypted = content[userIdMy];
      if (encrypted is String) {
        result["content"] = encrypted;
        print('✓ Extracted RSA content for user');
      }
    } else {
      print('✗ No content for user $userIdMy');
    }
  }

  return result;
}

Future<Map<String, dynamic>> decryptMessageEndToEndFull(
  Map<String, dynamic> data,
  String chatId,
) async {
  try {
    final content = data['content'];
    final encryptionType = data['encrypted'] as String?;

    if (content == null) {
      return data;
    }

    final Map<String, dynamic> decryptedData = Map<String, dynamic>.from(data);

    if (encryptionType == "ChaCha20-Poly1305") {
      if (content is Map && content.containsKey('key') && content.containsKey('data')) {
        decryptedData['content'] = await _decryptChaCha20ContentFull(
          content as Map<String, dynamic>,
          chatId,
        );
      } else {
        print('✗ Invalid ChaCha20 content structure');
      }
    } else if (encryptionType == "QUANTUM-AES-256") {
      if (content is Map && content.containsKey('key') && content.containsKey('data')) {
        decryptedData['content'] = await _decryptQuantumContentFull(
          content as Map<String, dynamic>,
          chatId,
        );
      } else {
        print('✗ Invalid quantum content structure');
      }
    } else if (content is String && isBase64(content)) {
      decryptedData['content'] = await _decryptRSAContent(content, chatId);
    }

    return decryptedData;
  } catch (e, stackTrace) {
    print('✗ Error in decryptMessageEndToEndFull: $e');
    print('Stack trace: $stackTrace');
    return data;
  }
}

Future<String> _quantumDecryptWithKey(
  String encryptedData,
  List<int> quantumKey,
) async {
  try {
    final combined = jsonDecode(encryptedData) as Map<String, dynamic>;
    if (combined.containsKey('iv') && combined.containsKey('data')) {
      return await _aesGcmDecrypt(combined, quantumKey);
    } else if (combined.containsKey('data') && combined.containsKey('method')) {
      final method = combined['method'] as String;
      
      if (method == 'OTP') {
        return _oneTimePadDecrypt(combined['data'] as String, quantumKey);
      } else if (method == 'AES-256-GCM') {
        return await _aesGcmDecrypt(combined, quantumKey);
      }
    } else if (combined.containsKey('data')) {
      return _oneTimePadDecrypt(combined['data'] as String, quantumKey);
    }

    return '';
  } catch (e, stackTrace) {
    print('✗ Quantum decryption error: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}
