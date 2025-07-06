import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:asn1lib/asn1lib.dart';
import 'package:pointycastle/api.dart' as crypto;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:http/http.dart' as http;

// --- RSA PEM ---
RSAPublicKey parsePublicKeyFromPem(String pemString) {
  final lines = pemString
      .split('\n')
      .where((line) => !line.startsWith('-----BEGIN') && !line.startsWith('-----END'))
      .toList();

  final base64Str = lines.join('');
  final bytes = base64.decode(base64Str);
  final asn1Parser = ASN1Parser(bytes);
  final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;

  if (topLevelSeq.elements.length == 2 &&
      topLevelSeq.elements[0] is ASN1Integer &&
      topLevelSeq.elements[1] is ASN1Integer) {
    final modulus = (topLevelSeq.elements[0] as ASN1Integer).valueAsBigInteger;
    final exponent = (topLevelSeq.elements[1] as ASN1Integer).valueAsBigInteger;
    return RSAPublicKey(modulus!, exponent!);
  }

  final publicKeyBitString = topLevelSeq.elements[1] as ASN1BitString;
  final publicKeyAsn = ASN1Parser(publicKeyBitString.valueBytes!());
  final publicKeySeq = publicKeyAsn.nextObject() as ASN1Sequence;

  final modulus = (publicKeySeq.elements[0] as ASN1Integer).valueAsBigInteger;
  final exponent = (publicKeySeq.elements[1] as ASN1Integer).valueAsBigInteger;
  return RSAPublicKey(modulus!, exponent!);
}

String encodePublicKeyToPemPKCS1(RSAPublicKey publicKey) {
  final algorithmSeq = ASN1Sequence();
  algorithmSeq.add(ASN1Integer(publicKey.modulus!));
  algorithmSeq.add(ASN1Integer(publicKey.exponent!));
  final dataBase64 = base64.encode(algorithmSeq.encodedBytes);
  return '''-----BEGIN RSA PUBLIC KEY-----\n${_chunked(dataBase64)}\n-----END RSA PUBLIC KEY-----''';
}

String _chunked(String str) {
  final chunkSize = 64;
  final chunks = <String>[];
  for (var i = 0; i < str.length; i += chunkSize) {
    chunks.add(str.substring(i, i + chunkSize > str.length ? str.length : i + chunkSize));
  }
  return chunks.join('\n');
}

// --- AES ---
Uint8List aesEncrypt(Uint8List key, Uint8List iv, Uint8List data) {
  final cipher = CBCBlockCipher(AESFastEngine());
  final padding = PKCS7Padding();

  cipher.init(true, ParametersWithIV(KeyParameter(key), iv));
  final paddedData = pad(data, padding, cipher.blockSize);

  final out = Uint8List(paddedData.length);
  var offset = 0;
  while (offset < paddedData.length) {
    cipher.processBlock(paddedData, offset, out, offset);
    offset += cipher.blockSize;
  }
  return out;
}

Uint8List pad(Uint8List data, Padding padding, int blockSize) {
  final padCount = blockSize - (data.length % blockSize);
  final padded = Uint8List(data.length + padCount)..setRange(0, data.length, data);
  padding.addPadding(padded, data.length);
  return padded;
}

// --- RSA ---
Uint8List rsaEncrypt(RSAPublicKey publicKey, Uint8List data) {
  final encryptor = OAEPEncoding(RSAEngine());
  encryptor.init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
  return _processInBlocks(encryptor, data);
}

Uint8List _processInBlocks(AsymmetricBlockCipher engine, Uint8List input) {
  final numBlocks = (input.length / engine.inputBlockSize).ceil();
  final output = BytesBuilder();
  for (var i = 0; i < numBlocks; i++) {
    final start = i * engine.inputBlockSize;
    final end = start + engine.inputBlockSize;
    final chunk = input.sublist(start, end > input.length ? input.length : end);
    final processed = engine.process(chunk);
    output.add(processed);
  }
  return output.toBytes();
}

// --- Генерація ключів ---
crypto.SecureRandom _getSecureRandom() {
  final secureRandom = FortunaRandom();
  final seedSource = Random.secure();
  final seeds = <int>[];
  for (int i = 0; i < 32; i++) {
    seeds.add(seedSource.nextInt(256));
  }
  secureRandom.seed(crypto.KeyParameter(Uint8List.fromList(seeds)));
  return secureRandom;
}

Future<AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>> generateRSAkeyPair({int bitLength = 2048}) async {
  final keyGen = RSAKeyGenerator()
    ..init(crypto.ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
      _getSecureRandom(),
    ));
  final pair = keyGen.generateKeyPair();
  return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
    pair.publicKey as RSAPublicKey,
    pair.privateKey as RSAPrivateKey,
  );
}

Uint8List generateRandomBytes(int length) {
  final secureRandom = SecureRandom('Fortuna')
    ..seed(KeyParameter(Uint8List.fromList(
        List<int>.generate(32, (_) => DateTime.now().millisecondsSinceEpoch % 256))));
  return secureRandom.nextBytes(length);
}







Uint8List rsaDecrypt(RSAPrivateKey privateKey, Uint8List encrypted) {
  final decryptor = OAEPEncoding(RSAEngine()); // або PKCS1Encoding(RSAEngine())
  decryptor.init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
  return _processInBlocks(decryptor, encrypted);
}

Future<String> decryptServerResponse(
  Map<String, dynamic> responseJson,
  RSAPrivateKey privateKey,
) async {
  final encryptedKeyBase64 = responseJson['data']['key'] as String;
  final encryptedDataStr = responseJson['data']['data'] as String;

  // 1. Розшифрувати AES ключ приватним RSA ключем
  final encryptedKey = base64Decode(encryptedKeyBase64);
  final aesKey = rsaDecrypt(privateKey, encryptedKey);

  // 2. Розділити data на IV і зашифровані дані
  final parts = encryptedDataStr.split('.');
  if (parts.length != 2) {
    throw Exception('Invalid encrypted data format');
  }

  final iv = base64Decode(parts[0]);
  final encryptedData = base64Decode(parts[1]);

  // 3. Розшифрувати AES дані
  final decryptedBytes = aesDecrypt(aesKey, iv, encryptedData);

  // 4. Конвертувати у рядок JSON
  return utf8.decode(decryptedBytes);
}



Uint8List aesDecrypt(Uint8List key, Uint8List iv, Uint8List data) {
  final cipher = CBCBlockCipher(AESFastEngine());
  final padding = PKCS7Padding();

  cipher.init(false, ParametersWithIV(KeyParameter(key), iv));

  final out = Uint8List(data.length);
  var offset = 0;
  while (offset < data.length) {
    cipher.processBlock(data, offset, out, offset);
    offset += cipher.blockSize;
  }

  return removePadding(out, padding);
}

Uint8List removePadding(Uint8List data, Padding padding) {
  final padCount = padding.padCount(data);
  return data.sublist(0, data.length - padCount);
}








Future<String> getServerPublicKey() async {
  final response = await http.get(Uri.parse('http://192.168.68.105:3000/public_key'));
  if (response.statusCode != 200) {
    throw Exception('Failed to get public key from server');
  }
  final body = jsonDecode(response.body);
  return body["key"];
}
