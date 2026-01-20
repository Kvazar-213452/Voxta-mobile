import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../../models/storage_chat_key.dart';
import '../../utils/crypto/make_key_chat.dart';

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
  if (messages is! List) return data;

  for (final message in messages) {
    if (message is! Map<String, dynamic>) continue;

    if (message["type"] == "file") {
      continue;
    }

    final content = message["content"];

    if (content is! String || content.isEmpty) continue;

    final base64Pattern = RegExp(r'^[A-Za-z0-9+/=]+$');
    final looksEncrypted =
        base64Pattern.hasMatch(content) && content.length % 4 == 0;

    if (!looksEncrypted) continue;

    try {
      message["content"] = decryptText(content, info?["keyAES"]);
    } catch (e) {
      print("Не вдалося розшифрувати повідомлення ${message["_id"]}: $e");
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
        print("Stack trace: $stackTrace");
      }
    }

    return message;
  } catch (e, stackTrace) {
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

  for (var msg in messages) {
    final message = Map<String, dynamic>.from(msg);
    final content = message["content"];

    try {
      // ===== MAP CASE (E2E MESSAGE) =====
      if (content is Map) {
        if (content.containsKey(userIdMy)) {
          final encrypted = content[userIdMy];

          if (encrypted is String && isBase64(encrypted)) {
            // 👉 тут викликаєш AES/RSA decrypt
            // final decrypted = decrypt(encrypted);

            message["content"] = encrypted; // тимчасово без decrypt
          }
        }
      }
      // ===== STRING CASE =====
      else if (content is String) {
        // якщо plaintext — пропускаємо
        if (!isBase64(content)) {
          newMessages.add(message);
          continue;
        }

        // інакше можеш пробувати decrypt
      }
    } catch (e) {
      print("Decrypt error ${message['_id']}: $e");
    }

    newMessages.add(message);
  }

  result["messages"] = newMessages;

  return result;
}

bool isBase64(String str) {
  final regex = RegExp(r'^[A-Za-z0-9+/]+={0,2}$');
  return regex.hasMatch(str) && str.length % 4 == 0;
}

Future<Map<String, dynamic>> decryptMessagesEndToEndFull(
  Map<String, dynamic> data,
  String chatId,
) async {
  final info = await ChatKeysDB.getChatInfo(chatId);
  final privateKeys = info?["privateKeys"];

  if (privateKeys == null || privateKeys.isEmpty) {
    print('No private keys available for decryption');
    return data;
  }

  if (data['messages'] == null || data['messages'].isEmpty) {
    return data;
  }

  final Map<String, dynamic> decryptedData = Map<String, dynamic>.from(data);
  final List<dynamic> messages = List<dynamic>.from(data['messages']);

  for (int i = 0; i < messages.length; i++) {
    final message = Map<String, dynamic>.from(messages[i]);
    final String? encryptedContent = message['content'];

    if (encryptedContent == null || encryptedContent.isEmpty) {
      continue;
    }

    bool decrypted = false;

    for (var privateKey in privateKeys) {
      try {
        final decryptedContent = RSACrypto.decrypt(
          encryptedContent,
          privateKey,
        );

        message['content'] = decryptedContent;
        messages[i] = message;
        decrypted = true;
        break;
      } catch (e) {
        continue;
      }
    }

    if (!decrypted) {
      print(
        'Warning: Could not decrypt message ${message['_id']} with any available key',
      );
    }
  }

  decryptedData['messages'] = messages;

  return decryptedData;
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

  // Check if content is in E2E format (Map with userId keys)
  if (content is Map) {
    if (content.containsKey(userIdMy)) {
      final encrypted = content[userIdMy];

      if (encrypted is String) {
        result["content"] = encrypted;
        print('Extracted E2E content for user $userIdMy');
      }
    } else {
      print('E2E content does not contain key for user $userIdMy');
    }
  } else if (content is String) {
    // Content is already a string (encrypted), no need to extract
    print('Content is already in string format (likely already encrypted)');
  }

  return result;
}






Future<Map<String, dynamic>> decryptMessageEndToEndFull(Map<String, dynamic> data, String chatId) async {
  try {
    final info = await ChatKeysDB.getChatInfo(chatId);
    final privateKeys = info?["privateKeys"];
    
    // Якщо немає приватних ключів або content, повертаємо дані без змін
    if (privateKeys == null || privateKeys.isEmpty) {
      print('No private keys available for decryption');
      return data;
    }
    
    final String? encryptedContent = data['content'];
    
    if (encryptedContent == null || encryptedContent.isEmpty) {
      return data;
    }
    
    // Створюємо копію даних для модифікації
    final Map<String, dynamic> decryptedData = Map<String, dynamic>.from(data);
    
    // Перебираємо всі доступні приватні ключі
    for (var privateKey in privateKeys) {
      try {
        // Спроба розшифрувати повідомлення
        final decryptedContent = RSACrypto.decrypt(encryptedContent, privateKey);
        
        // Якщо розшифрування успішне, оновлюємо content
        decryptedData['content'] = decryptedContent;
        
        print('Message ${data['_id']} decrypted successfully');
        return decryptedData;
      } catch (e) {
        // Якщо не вдалося розшифрувати цим ключем, пробуємо наступний
        continue;
      }
    }
    
    // Якщо жоден ключ не підійшов
    print('Warning: Could not decrypt message ${data['_id']} with any available key');
    return data; // Повертаємо оригінальні дані
  } catch (e, stackTrace) {
    print('Error in decryptSingleMessage: $e');
    print('Stack trace: $stackTrace');
    return data; // У разі будь-якої помилки повертаємо оригінальні дані
  }
}




// jsonDecode