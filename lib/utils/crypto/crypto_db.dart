import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

Uint8List _pad(Uint8List data) {
  final padder = PKCS7Padding();
  final padLength = 16 - (data.length % 16);
  final paddedData = Uint8List(data.length + padLength)..setAll(0, data);
  padder.addPadding(paddedData, data.length);
  return paddedData;
}

Uint8List _unpad(Uint8List paddedData) {
  final padder = PKCS7Padding();
  final padCount = padder.padCount(paddedData);
  return paddedData.sublist(0, paddedData.length - padCount);
}

String encryptText(String plainText, String base64Key, String base64Iv) {
  final key = base64.decode(base64Key);
  final iv = base64.decode(base64Iv);

  final keyParam = KeyParameter(Uint8List.fromList(key));
  final params = ParametersWithIV<KeyParameter>(keyParam, Uint8List.fromList(iv));

  final cipher = CBCBlockCipher(AESEngine())
    ..init(true, params);

  final input = _pad(Uint8List.fromList(utf8.encode(plainText)));
  final output = Uint8List(input.length);

  for (int offset = 0; offset < input.length; offset += 16) {
    cipher.processBlock(input, offset, output, offset);
  }

  return base64.encode(output);
}


String decryptText(String encryptedBase64, String base64Key, String base64Iv) {
  final key = base64.decode(base64Key);
  final iv = base64.decode(base64Iv);

  final encrypted = base64.decode(encryptedBase64);

  final keyParam = KeyParameter(key);
  final params = ParametersWithIV<KeyParameter>(keyParam, iv);

  final cipher = CBCBlockCipher(AESEngine())
    ..init(false, params);

  final output = Uint8List(encrypted.length);

  for (int offset = 0; offset < encrypted.length; offset += 16) {
    cipher.processBlock(encrypted, offset, output, offset);
  }

  final unpadded = _unpad(output);
  return utf8.decode(unpadded);
}
