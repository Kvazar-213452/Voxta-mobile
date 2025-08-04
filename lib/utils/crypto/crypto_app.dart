import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/asn1.dart';

RSAPublicKey parsePublicKeyFromPem(String pem) {
  String keyData = pem
      .replaceAll('-----BEGIN RSA PUBLIC KEY-----', '')
      .replaceAll('-----END RSA PUBLIC KEY-----', '')
      .replaceAll('-----BEGIN PUBLIC KEY-----', '')
      .replaceAll('-----END PUBLIC KEY-----', '')
      .replaceAll('\n', '')
      .replaceAll('\r', '')
      .replaceAll(' ', '');

  final keyBytes = base64.decode(keyData);
  final asn1Parser = ASN1Parser(keyBytes);
  final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
  
  final modulus = (topLevelSeq.elements![0] as ASN1Integer).integer!;
  final exponent = (topLevelSeq.elements![1] as ASN1Integer).integer!;

  return RSAPublicKey(modulus, exponent);
}

BigInt _bytesToBigInt(Uint8List bytes) {
  BigInt result = BigInt.zero;
  for (int byte in bytes) {
    result = (result << 8) + BigInt.from(byte);
  }
  return result;
}

Uint8List _bigIntToBytes(BigInt bigInt) {
  if (bigInt == BigInt.zero) return Uint8List.fromList([0]);
  
  var bytes = <int>[];
  while (bigInt > BigInt.zero) {
    bytes.insert(0, (bigInt & BigInt.from(0xff)).toInt());
    bigInt = bigInt >> 8;
  }
  return Uint8List.fromList(bytes);
}

String encodePublicKeyToPemPKCS1(RSAPublicKey publicKey) {
  final sequence = ASN1Sequence();
  sequence.add(ASN1Integer(publicKey.modulus!));
  sequence.add(ASN1Integer(publicKey.exponent!));
  
  final publicKeyBytes = sequence.encode();
  final base64Key = base64.encode(publicKeyBytes);
  
  return '-----BEGIN RSA PUBLIC KEY-----\n${_formatBase64(base64Key)}\n-----END RSA PUBLIC KEY-----';
}

String _formatBase64(String base64) {
  final regex = RegExp(r'.{1,64}');
  return regex.allMatches(base64).map((m) => m.group(0)).join('\n');
}

Map<String, Uint8List> aesEncrypt(Uint8List key, Uint8List nonce, Uint8List data) {
  final cipher = GCMBlockCipher(AESEngine());
  final params = AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0));
  cipher.init(true, params);

  final encryptedBytes = cipher.process(data);
  
  final encryptedData = encryptedBytes.sublist(0, encryptedBytes.length - 16);
  final authTag = encryptedBytes.sublist(encryptedBytes.length - 16);
  
  return {
    'encrypted': encryptedData,
    'authTag': authTag,
  };
}

Uint8List rsaEncrypt(RSAPublicKey publicKey, Uint8List data) {
  final encryptor = OAEPEncoding(RSAEngine());
  encryptor.init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
  return encryptor.process(data);
}

Uint8List rsaDecrypt(RSAPrivateKey privateKey, Uint8List encrypted) {
  final decryptor = OAEPEncoding(RSAEngine());
  decryptor.init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
  return decryptor.process(encrypted);
}

Uint8List generateRandomBytes(int length) {
  final random = Random.secure();
  final bytes = Uint8List(length);
  for (int i = 0; i < length; i++) {
    bytes[i] = random.nextInt(256);
  }
  return bytes;
}

Future<Map<String, String>> encryptMessage(String message, String serverPublicKeyPem) async {
  final serverPublicKey = parsePublicKeyFromPem(serverPublicKeyPem);
  
  final aesKey = generateRandomBytes(32);
  
  final nonce = generateRandomBytes(12);
  
  final messageBytes = utf8.encode(message);
  final aesResult = aesEncrypt(aesKey, nonce, messageBytes);
  final encryptedData = aesResult['encrypted']!;
  final authTag = aesResult['authTag']!;
  
  final encryptedKey = rsaEncrypt(serverPublicKey, aesKey);
  
  final dataString = base64.encode(nonce) + '.' + 
                    base64.encode(authTag) + '.' + 
                    base64.encode(encryptedData);
  
  return {
    'key': base64.encode(encryptedKey),
    'data': dataString,
  };
}

Uint8List aesDecrypt(Uint8List key, Uint8List nonce, Uint8List encryptedData, Uint8List authTag) {
  final cipher = GCMBlockCipher(AESEngine());
  final params = AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0));
  cipher.init(false, params);

  final encryptedWithTag = Uint8List.fromList([...encryptedData, ...authTag]);
  final decryptedBytes = cipher.process(encryptedWithTag);
  
  return decryptedBytes;
}

Future<String> decryptServerResponse(
  Map<String, dynamic> responseJson,
  RSAPrivateKey privateKey,
) async {
  final encryptedKeyBase64 = responseJson['data']['key'] as String;
  final encryptedDataStr = responseJson['data']['data'] as String;

  final encryptedKey = base64Decode(encryptedKeyBase64);
  final aesKey = rsaDecrypt(privateKey, encryptedKey);

  final parts = encryptedDataStr.split('.');
  if (parts.length != 3) {
    throw Exception('Неправильний формат зашифрованих даних');
  }

  final nonce = base64Decode(parts[0]);
  final authTag = base64Decode(parts[1]);
  final encryptedData = base64Decode(parts[2]);

  final decryptedBytes = aesDecrypt(aesKey, nonce, encryptedData, authTag);

  return utf8.decode(decryptedBytes);
}
