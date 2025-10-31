import 'dart:convert';
import 'dart:math';
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

Future<Map<String, dynamic>> decryptMessages(Map<String, dynamic> data) async {
  final keyChat = await ChatKeysDB.getKey(data["chatId"]);

  if (keyChat == "") {
    return data;
  }

  final messages = data["messages"];
  if (messages is! List) return data;

  for (final message in messages) {
    if (message is Map<String, dynamic>) {
      final content = message["content"];

      final base64Pattern = RegExp(r'^[A-Za-z0-9+/=]+$');
      final looksEncrypted =
          base64Pattern.hasMatch(content) && content.length % 4 == 0;

      if (looksEncrypted) {
        try {
          message["content"] = decryptText(content, keyChat);
        } catch (e) {
          print("Не вдалося розшифрувати повідомлення ${message["_id"]}: $e");
        }
      }
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
