import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../../models/storage_chat_key.dart';

String generateKey() {
  final random = Random.secure();
  final values = List<int>.generate(32, (i) => random.nextInt(256));
  return base64UrlEncode(values);
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
  final keyChat = await ChatKeysDB.getKey(data["chatId"]);

  if (keyChat.isEmpty) {
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
      message["content"] = decryptText(content, keyChat);
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
  final keyChat = await ChatKeysDB.getKey(chatId);

  if (keyChat.isEmpty) return message;

  final content = message["content"];
  if (content is! String) return message;

  final base64Pattern = RegExp(r'^[A-Za-z0-9+/=]+$');
  final looksEncrypted =
      base64Pattern.hasMatch(content) && content.length % 4 == 0;

  if (looksEncrypted) {
    try {
      final decrypted = decryptText(content, keyChat);
      message["content"] = decrypted;
    } catch (e) {
      print("Не вдалося розшифрувати повідомлення ${message["_id"]}: $e");
    }
  }

  return message;
}
