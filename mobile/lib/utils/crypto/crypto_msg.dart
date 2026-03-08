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
  print('═══ decryptMessages START ═══');
  print('Chat ID: ${data["chatId"]}');
  
  final info = await ChatKeysDB.getChatInfo(data["chatId"]);
  print('Chat info isEncrypted: ${info?["isEncrypted"]}');

  if (!info?["isEncrypted"]) {
    print('Chat is not encrypted, skipping AES decryption');
    return data;
  }

  final messages = data["messages"];
  if (messages is! List) {
    print('No messages found or invalid format');
    return data;
  }

  print('Processing ${messages.length} messages for AES decryption');

  for (int idx = 0; idx < messages.length; idx++) {
    final message = messages[idx];
    if (message is! Map<String, dynamic>) continue;

    print('--- Message $idx (ID: ${message["_id"]}) ---');
    print('Type: ${message["type"]}');
    print('Encrypted field: ${message["encrypted"]}');

    if (message["type"] == "file") {
      print('Skipping file type message');
      continue;
    }

    final content = message["content"];
    print('Content type: ${content.runtimeType}');
    print('Content value: ${content is String ? content.substring(0, min(50, content.length)) : content}');

    if (content is! String || content.isEmpty) {
      print('Content is not a string or is empty, skipping');
      continue;
    }

    final base64Pattern = RegExp(r'^[A-Za-z0-9+/=]+$');
    final looksEncrypted =
        base64Pattern.hasMatch(content) && content.length % 4 == 0;

    print('Looks encrypted (base64): $looksEncrypted');

    if (!looksEncrypted) {
      print('Does not look encrypted, skipping');
      continue;
    }

    try {
      final decrypted = decryptText(content, info?["keyAES"]);
      message["content"] = decrypted;
      print('✓ Successfully decrypted message $idx');
      print('Decrypted content: ${decrypted.substring(0, min(50, decrypted.length))}');
    } catch (e, stackTrace) {
      print('✗ Failed to decrypt message ${message["_id"]}: $e');
      print('Stack trace: $stackTrace');
    }
  }

  print('═══ decryptMessages END ═══\n');
  return data;
}

Future<Map<String, dynamic>> decryptMessage(
  Map<String, dynamic> message,
  String chatId,
) async {
  print('═══ decryptMessage START ═══');
  print('Chat ID: $chatId');
  print('Message ID: ${message["_id"]}');
  
  try {
    final info = await ChatKeysDB.getChatInfo(chatId);
    print('Chat info isEncrypted: ${info?["isEncrypted"]}');

    if (!info?["isEncrypted"]) {
      print('Chat is not encrypted, returning original message');
      return message;
    }

    final content = message["content"];
    print('Content type: ${content.runtimeType}');

    if (content is! String) {
      print('Content is not a string, returning original message');
      return message;
    }

    final base64Pattern = RegExp(r'^[A-Za-z0-9+/=]+$');
    final looksEncrypted =
        base64Pattern.hasMatch(content) && content.length % 4 == 0;

    print('Looks encrypted: $looksEncrypted');

    if (looksEncrypted) {
      try {
        final decrypted = decryptText(content, info?["keyAES"]);
        message["content"] = decrypted;
        print('✓ Successfully decrypted message');
      } catch (e, stackTrace) {
        print('✗ Decryption failed: $e');
        print('Stack trace: $stackTrace');
      }
    }

    print('═══ decryptMessage END ═══\n');
    return message;
  } catch (e, stackTrace) {
    print('✗ Error in decryptMessage: $e');
    print('Stack trace: $stackTrace');
    return message;
  }
}

/// Перший етап: витягування контенту для конкретного користувача
Future<Map<String, dynamic>> decryptMessagesEndToEnd(
  Map<String, dynamic> data,
  String userIdMy,
) async {
  print('═══ decryptMessagesEndToEnd START ═══');
  print('User ID: $userIdMy');
  print('Chat ID: ${data["chatId"]}');
  
  final result = Map<String, dynamic>.from(data);

  if (!result.containsKey("messages")) {
    print('No messages field found');
    return result;
  }

  final List messages = List.from(result["messages"]);
  print('Processing ${messages.length} messages');
  final List newMessages = [];

  for (int idx = 0; idx < messages.length; idx++) {
    var msg = messages[idx];
    final message = Map<String, dynamic>.from(msg);
    final content = message["content"];
    final encryptionType = message["encrypted"] as String?;

    print('--- Message $idx (ID: ${message["_id"]}) ---');
    print('Encryption type: $encryptionType');
    print('Content type: ${content.runtimeType}');

    try {
      // Перевірка на ChaCha20-Poly1305 шифрування
      if (encryptionType == "ChaCha20-Poly1305") {
        print('Processing ChaCha20-Poly1305 encryption');
        
        if (content is Map) {
          print('Content is Map with keys: ${content.keys}');
          
          if (content.containsKey(userIdMy)) {
            print('Found content for user $userIdMy');
            final userContent = content[userIdMy];
            print('User content type: ${userContent.runtimeType}');
            
            if (userContent is Map) {
              print('User content keys: ${userContent.keys}');
              print('Has key field: ${userContent.containsKey("key")}');
              print('Has data field: ${userContent.containsKey("data")}');
            }
            
            message["content"] = userContent;
            print('✓ Extracted ChaCha20 content for user');
          } else {
            print('✗ No content found for user $userIdMy in ChaCha20 message');
            print('Available users: ${content.keys}');
          }
        } else {
          print('✗ Content is not a Map for ChaCha20 message');
        }
      }
      // Перевірка на квантове шифрування
      else if (encryptionType == "QUANTUM-AES-256") {
        print('Processing QUANTUM-AES-256 encryption');
        
        if (content is Map) {
          print('Content is Map with keys: ${content.keys}');
          
          if (content.containsKey(userIdMy)) {
            print('Found content for user $userIdMy');
            final userContent = content[userIdMy];
            print('User content type: ${userContent.runtimeType}');
            
            if (userContent is Map) {
              print('User content keys: ${userContent.keys}');
              print('Has key field: ${userContent.containsKey("key")}');
              print('Has data field: ${userContent.containsKey("data")}');
            }
            
            message["content"] = userContent;
            print('✓ Extracted quantum content for user');
          } else {
            print('✗ No content found for user $userIdMy in quantum message');
            print('Available users: ${content.keys}');
          }
        } else {
          print('✗ Content is not a Map for quantum message');
        }
      } else if (encryptionType == "RSA-2048" || content is Map) {
        print('Processing RSA-2048 encryption');
        
        if (content is Map && content.containsKey(userIdMy)) {
          final encrypted = content[userIdMy];
          print('Found encrypted content for user $userIdMy');
          print('Encrypted type: ${encrypted.runtimeType}');
          
          if (encrypted is String && isBase64(encrypted)) {
            message["content"] = encrypted;
            print('✓ Extracted RSA content (length: ${encrypted.length})');
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
  print('═══ decryptMessagesEndToEnd END ═══\n');
  return result;
}

/// Другий етап: повне дешифрування (RSA, квантове або ChaCha20)
Future<Map<String, dynamic>> decryptMessagesEndToEndFull(
  Map<String, dynamic> data,
  String chatId,
) async {
  print('═══ decryptMessagesEndToEndFull START ═══');
  print('Chat ID: $chatId');
  
  if (data['messages'] == null || data['messages'].isEmpty) {
    print('No messages to decrypt');
    return data;
  }

  final Map<String, dynamic> decryptedData = Map<String, dynamic>.from(data);
  final List<dynamic> messages = List<dynamic>.from(data['messages']);
  print('Processing ${messages.length} messages');

  for (int i = 0; i < messages.length; i++) {
    final message = Map<String, dynamic>.from(messages[i]);
    final content = message['content'];
    final encryptionType = message['encrypted'] as String?;

    print('--- Message $i (ID: ${message["_id"]}) ---');
    print('Encryption type: $encryptionType');
    print('Content type: ${content.runtimeType}');

    try {
      // Обробка ChaCha20-Poly1305
      if (encryptionType == "ChaCha20-Poly1305") {
        print('Processing ChaCha20-Poly1305 decryption');
        
        if (content is Map) {
          print('Content is Map with keys: ${content.keys}');
          print('Has key: ${content.containsKey("key")}');
          print('Has data: ${content.containsKey("data")}');
          
          if (content.containsKey('key') && content.containsKey('data')) {
            print('Attempting ChaCha20 decryption...');
            final decrypted = await _decryptChaCha20ContentFull(
              content as Map<String, dynamic>,
              chatId,
            );
            
            if (decrypted.isNotEmpty) {
              message['content'] = decrypted;
              messages[i] = message;
              print('✓ ChaCha20 decryption successful');
              print('Decrypted content: ${decrypted.substring(0, min(50, decrypted.length))}');
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
      // Обробка QUANTUM-AES-256
      else if (encryptionType == "QUANTUM-AES-256") {
        print('Processing QUANTUM-AES-256 decryption');
        
        if (content is Map) {
          print('Content is Map with keys: ${content.keys}');
          print('Has key: ${content.containsKey("key")}');
          print('Has data: ${content.containsKey("data")}');
          
          if (content.containsKey('key') && content.containsKey('data')) {
            print('Attempting quantum decryption...');
            final decrypted = await _decryptQuantumContentFull(
              content as Map<String, dynamic>,
              chatId,
            );
            
            if (decrypted.isNotEmpty) {
              message['content'] = decrypted;
              messages[i] = message;
              print('✓ Quantum decryption successful');
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
      // Обробка RSA-2048
      else if (encryptionType == "RSA-2048" || (content is String && isBase64(content))) {
        print('Processing RSA-2048 decryption');
        print('Content length: ${(content as String).length}');
        
        final decrypted = await _decryptRSAContent(content, chatId);
        
        if (decrypted != content) {
          message['content'] = decrypted;
          messages[i] = message;
          print('✓ RSA decryption successful');
          print('Decrypted content: ${decrypted.substring(0, min(50, decrypted.length))}');
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
  print('═══ decryptMessagesEndToEndFull END ═══\n');
  return decryptedData;
}

/// Дешифрування RSA контенту
Future<String> _decryptRSAContent(String encryptedContent, String chatId) async {
  print('→ _decryptRSAContent START');
  print('Chat ID: $chatId');
  print('Encrypted content length: ${encryptedContent.length}');
  
  final info = await ChatKeysDB.getChatInfo(chatId);
  final privateKeys = info?["privateKeys"];

  print('Private keys count: ${privateKeys?.length ?? 0}');

  if (privateKeys == null || privateKeys.isEmpty) {
    print('✗ No private keys available for RSA decryption');
    return encryptedContent;
  }

  for (int i = 0; i < privateKeys.length; i++) {
    final privateKey = privateKeys[i];
    print('Trying private key $i (length: ${privateKey.toString().length})');
    
    try {
      final decryptedContent = RSACrypto.decrypt(encryptedContent, privateKey);
      print('✓ RSA decryption successful with key $i');
      print('Decrypted length: ${decryptedContent.length}');
      return decryptedContent;
    } catch (e) {
      print('✗ Failed with key $i: $e');
      continue;
    }
  }

  print('✗ Failed to decrypt with any available RSA key');
  return encryptedContent;
}

/// Дешифрування ChaCha20 контенту
Future<String> _decryptChaCha20ContentFull(
  Map<String, dynamic> content,
  String chatId,
) async {
  print('→ _decryptChaCha20ContentFull START');
  print('Chat ID: $chatId');
  print('Content keys: ${content.keys}');
  
  try {
    final encryptedKey = content['key'] as String?;
    final encryptedData = content['data'] as String?;
    
    print('Encrypted key preview: ${encryptedKey?.substring(0, min(50, encryptedKey.length ?? 0))}...');
    print('Encrypted data preview: ${encryptedData?.substring(0, min(50, encryptedData.length ?? 0))}...');
    
    if (encryptedKey == null || encryptedData == null) {
      print('✗ Missing ChaCha20 encryption data');
      print('Has key: ${encryptedKey != null}');
      print('Has data: ${encryptedData != null}');
      return '';
    }

    // Отримання приватного RSA ключа
    final privateKey = await ChatKeysDB.getPrivateKey(chatId);
    
    if (privateKey == null || privateKey.isEmpty) {
      print('✗ Private RSA key not found for ChaCha20 decryption');
      return '';
    }

    print('Private key length: ${privateKey.length}');
    print('Attempting to decrypt ChaCha20 key with RSA...');

    // Розшифрування ключа ChaCha20 за допомогою RSA
    final chaCha20KeyBase64 = RSACrypto.decrypt(encryptedKey, privateKey);
    print('✓ ChaCha20 key decrypted (base64 length: ${chaCha20KeyBase64.length})');
    
    final chaCha20Key = base64Decode(chaCha20KeyBase64);
    print('ChaCha20 key bytes length: ${chaCha20Key.length}');
    
    // Розшифрування даних ключем ChaCha20
    print('Attempting to decrypt data with ChaCha20 key...');
    final decryptedContent = await _chaCha20DecryptWithKey(
      encryptedData,
      chaCha20Key,
    );

    print('✓ ChaCha20 decryption complete');
    print('Decrypted content length: ${decryptedContent.length}');
    print('Decrypted content preview: ${decryptedContent.substring(0, min(100, decryptedContent.length))}');
    return decryptedContent;
  } catch (e, stackTrace) {
    print('✗ Failed to decrypt ChaCha20 content: $e');
    print('Stack trace: $stackTrace');
    return '';
  }
}

/// Розшифрування даних за допомогою ключа ChaCha20
Future<String> _chaCha20DecryptWithKey(
  String encryptedData,
  List<int> chaCha20Key,
) async {
  print('→ _chaCha20DecryptWithKey START');
  print('Encrypted data length: ${encryptedData.length}');
  print('ChaCha20 key length: ${chaCha20Key.length}');
  
  try {
    // Парсинг JSON з nonce та даними
    final combined = jsonDecode(encryptedData) as Map<String, dynamic>;
    print('Decoded JSON successfully');
    print('JSON keys: ${combined.keys}');
    
    final nonceBase64 = combined['nonce'] as String;
    final dataBase64 = combined['data'] as String;
    
    print('Nonce base64 length: ${nonceBase64.length}');
    print('Data base64 length: ${dataBase64.length}');
    
    final nonce = Uint8List.fromList(base64Decode(nonceBase64));
    final encryptedBytes = Uint8List.fromList(base64Decode(dataBase64));
    
    print('Nonce bytes length: ${nonce.length}');
    print('Encrypted bytes length: ${encryptedBytes.length}');
    
    // Ініціалізація ChaCha20 для розшифрування
    final cipher = ChaCha20Engine();
    final params = ParametersWithIV(
      KeyParameter(Uint8List.fromList(chaCha20Key)),
      nonce,
    );
    cipher.init(false, params); // false для розшифрування
    
    print('ChaCha20 cipher initialized for decryption');
    
    // Розшифровуємо побайтово
    final decrypted = Uint8List(encryptedBytes.length);
    for (var i = 0; i < encryptedBytes.length; i++) {
      decrypted[i] = cipher.returnByte(encryptedBytes[i]);
    }
    
    print('Decryption complete, converting to UTF-8 string...');
    final result = utf8.decode(decrypted);
    print('✓ ChaCha20 decryption successful, result length: ${result.length}');
    
    return result;
  } catch (e, stackTrace) {
    print('✗ ChaCha20 decryption error: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}

/// Дешифрування квантового контенту (повна версія)
Future<String> _decryptQuantumContentFull(
  Map<String, dynamic> content,
  String chatId,
) async {
  print('→ _decryptQuantumContentFull START');
  print('Chat ID: $chatId');
  print('Content keys: ${content.keys}');
  
  try {
    final encryptedKey = content['key'] as String?;
    final encryptedData = content['data'] as String?;
    
    print('Encrypted key: ${encryptedKey?.substring(0, min(50, encryptedKey.length ?? 0))}');
    print('Encrypted data: ${encryptedData?.substring(0, min(50, encryptedData.length ?? 0))}');
    
    if (encryptedKey == null || encryptedData == null) {
      print('✗ Missing quantum encryption data');
      print('Has key: ${encryptedKey != null}');
      print('Has data: ${encryptedData != null}');
      return '';
    }

    // Отримання приватного RSA ключа
    final privateKey = await ChatKeysDB.getPrivateKey(chatId);
    
    if (privateKey == null || privateKey.isEmpty) {
      print('✗ Private RSA key not found for quantum decryption');
      return '';
    }

    print('Private key length: ${privateKey.length}');
    print('Attempting to decrypt quantum key with RSA...');

    // Розшифрування квантового ключа за допомогою RSA
    final quantumKeyBase64 = RSACrypto.decrypt(encryptedKey, privateKey);
    print('✓ Quantum key decrypted (base64 length: ${quantumKeyBase64.length})');
    
    final quantumKey = base64Decode(quantumKeyBase64);
    print('Quantum key bytes length: ${quantumKey.length}');
    
    // Розшифрування даних квантовим ключем
    print('Attempting to decrypt data with quantum key...');
    final decryptedContent = await _quantumDecryptWithKey(
      encryptedData,
      quantumKey,
    );

    print('✓ Quantum decryption complete');
    print('Decrypted content length: ${decryptedContent.length}');
    return decryptedContent;
  } catch (e, stackTrace) {
    print('✗ Failed to decrypt quantum content: $e');
    print('Stack trace: $stackTrace');
    return '';
  }
}

/// One-Time Pad дешифрування
String _oneTimePadDecrypt(String encryptedBase64, List<int> key) {
  print('→ _oneTimePadDecrypt START');
  print('Encrypted base64 length: ${encryptedBase64.length}');
  print('Key length: ${key.length}');
  
  try {
    final encrypted = base64Decode(encryptedBase64);
    print('Decoded encrypted bytes length: ${encrypted.length}');
    
    final decrypted = List<int>.generate(
      encrypted.length,
      (i) => encrypted[i] ^ key[i % key.length],
    );
    
    final result = utf8.decode(decrypted);
    print('✓ OTP decryption successful, result length: ${result.length}');
    return result;
  } catch (e, stackTrace) {
    print('✗ OTP decryption error: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}

/// AES-256-GCM дешифрування
Future<String> _aesGcmDecrypt(
  Map<String, dynamic> combined,
  List<int> quantumKey,
) async {
  print('→ _aesGcmDecrypt START');
  print('Combined keys: ${combined.keys}');
  print('Quantum key length: ${quantumKey.length}');
  
  try {
    final ivBase64 = combined['iv'] as String;
    final dataBase64 = combined['data'] as String;
    
    print('IV base64 length: ${ivBase64.length}');
    print('Data base64 length: ${dataBase64.length}');
    
    final iv = base64Decode(ivBase64);
    print('IV bytes length: ${iv.length}');
    
    final encrypter = Encrypter(AES(
      Key(Uint8List.fromList(quantumKey)),
      mode: AESMode.gcm,
    ));
    
    print('Attempting AES-256-GCM decryption...');
    final decrypted = encrypter.decrypt64(
      dataBase64,
      iv: IV(Uint8List.fromList(iv)),
    );
    
    print('✓ AES-GCM decryption successful, result length: ${decrypted.length}');
    return decrypted;
  } catch (e, stackTrace) {
    print('✗ AES-GCM decryption error: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}

/// Перевірка чи є рядок Base64
bool isBase64(String str) {
  try {
    base64Decode(str);
    return true;
  } catch (e) {
    return false;
  }
}

/// Дешифрування одного повідомлення (end-to-end)
Map<String, dynamic> decryptMessageEndToEnd(
  Map<String, dynamic> message,
  String userIdMy,
) {
  print('═══ decryptMessageEndToEnd START ═══');
  print('User ID: $userIdMy');
  print('Message ID: ${message["_id"]}');
  
  final result = Map<String, dynamic>.from(message);

  if (!result.containsKey("content")) {
    print('No content field found');
    return result;
  }

  final content = result["content"];
  final encryptionType = result["encrypted"] as String?;

  print('Encryption type: $encryptionType');
  print('Content type: ${content.runtimeType}');

  if (encryptionType == "ChaCha20-Poly1305") {
    print('Processing ChaCha20 encryption');
    
    if (content is Map && content.containsKey(userIdMy)) {
      result["content"] = content[userIdMy];
      print('✓ Extracted ChaCha20 content for user');
    } else {
      print('✗ Content is not Map or missing user data');
    }
  } else if (encryptionType == "QUANTUM-AES-256") {
    print('Processing quantum encryption');
    
    if (content is Map && content.containsKey(userIdMy)) {
      result["content"] = content[userIdMy];
      print('✓ Extracted quantum content for user');
    } else {
      print('✗ Content is not Map or missing user data');
    }
  } else if (content is Map) {
    print('Processing RSA encryption');
    
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

  print('═══ decryptMessageEndToEnd END ═══\n');
  return result;
}

/// Повне дешифрування одного повідомлення
Future<Map<String, dynamic>> decryptMessageEndToEndFull(
  Map<String, dynamic> data,
  String chatId,
) async {
  print('═══ decryptMessageEndToEndFull START ═══');
  print('Chat ID: $chatId');
  print('Message ID: ${data["_id"]}');
  
  try {
    final content = data['content'];
    final encryptionType = data['encrypted'] as String?;

    print('Encryption type: $encryptionType');
    print('Content type: ${content.runtimeType}');

    if (content == null) {
      print('No content found');
      return data;
    }

    final Map<String, dynamic> decryptedData = Map<String, dynamic>.from(data);

    if (encryptionType == "ChaCha20-Poly1305") {
      print('Processing ChaCha20 decryption');
      
      if (content is Map && content.containsKey('key') && content.containsKey('data')) {
        decryptedData['content'] = await _decryptChaCha20ContentFull(
          content as Map<String, dynamic>,
          chatId,
        );
        print('✓ ChaCha20 decryption complete');
      } else {
        print('✗ Invalid ChaCha20 content structure');
      }
    } else if (encryptionType == "QUANTUM-AES-256") {
      print('Processing quantum decryption');
      
      if (content is Map && content.containsKey('key') && content.containsKey('data')) {
        decryptedData['content'] = await _decryptQuantumContentFull(
          content as Map<String, dynamic>,
          chatId,
        );
        print('✓ Quantum decryption complete');
      } else {
        print('✗ Invalid quantum content structure');
      }
    } else if (content is String && isBase64(content)) {
      print('Processing RSA decryption');
      
      decryptedData['content'] = await _decryptRSAContent(content, chatId);
      print('✓ RSA decryption complete');
    }

    print('═══ decryptMessageEndToEndFull END ═══\n');
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
  print('→ _quantumDecryptWithKey START');
  print('Encrypted data length: ${encryptedData.length}');
  print('Quantum key length: ${quantumKey.length}');
  
  try {
    final combined = jsonDecode(encryptedData) as Map<String, dynamic>;
    print('Decoded JSON successfully');
    print('JSON keys: ${combined.keys}');
    print('JSON content: $combined');
    
    // Визначаємо метод за структурою даних
    if (combined.containsKey('iv') && combined.containsKey('data')) {
      // AES-256-GCM: має і iv, і data
      print('Detected AES-256-GCM structure');
      return await _aesGcmDecrypt(combined, quantumKey);
    } else if (combined.containsKey('data') && combined.containsKey('method')) {
      // Явно вказаний метод
      final method = combined['method'] as String;
      print('Explicit method: $method');
      
      if (method == 'OTP') {
        return _oneTimePadDecrypt(combined['data'] as String, quantumKey);
      } else if (method == 'AES-256-GCM') {
        return await _aesGcmDecrypt(combined, quantumKey);
      }
    } else if (combined.containsKey('data')) {
      // Тільки data - OTP
      print('Detected OTP structure (only data field)');
      return _oneTimePadDecrypt(combined['data'] as String, quantumKey);
    }
    
    print('✗ Unknown structure: $combined');
    return '';
  } catch (e, stackTrace) {
    print('✗ Quantum decryption error: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}