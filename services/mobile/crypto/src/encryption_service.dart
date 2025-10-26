import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:pointycastle/export.dart';
import 'rsa_utils.dart';

class EncryptionService {
  static AsymmetricKeyPair generateRSAKeyPair() {
    final keyGen = RSAKeyGenerator();
    final secureRandom = FortunaRandom();
    
    final seedSource = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(256));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    final params = RSAKeyGeneratorParameters(BigInt.parse('65537'), 4096, 64);
    final rngParams = ParametersWithRandom(params, secureRandom);
    keyGen.init(rngParams);

    return keyGen.generateKeyPair();
  }

  static void saveKeyPair(AsymmetricKeyPair keyPair) {
    final publicKey = keyPair.publicKey as RSAPublicKey;
    final privateKey = keyPair.privateKey as RSAPrivateKey;
    
    final publicKeyPem = RSAUtils.encodePublicKeyToPkcs1(publicKey);
    final privateKeyPem = RSAUtils.encodePrivateKeyToPkcs8(privateKey);

    File('private_key.pem').writeAsStringSync(privateKeyPem);
    File('public_key.pem').writeAsStringSync(publicKeyPem);
    
    print('RSA ключі згенеровано та збережено');
  }

  static Map<String, String> encryptMessage(String publicRsaKey, String message) {
    final random = Random.secure();
    final aesKey = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      aesKey[i] = random.nextInt(256);
    }

    final nonce = Uint8List(12);
    for (int i = 0; i < 12; i++) {
      nonce[i] = random.nextInt(256);
    }

    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(KeyParameter(aesKey), 128, nonce, Uint8List(0));
    cipher.init(true, params);

    final messageBytes = utf8.encode(message);
    final encryptedBytes = cipher.process(messageBytes);
    
    final encryptedData = encryptedBytes.sublist(0, encryptedBytes.length - 16);
    final authTag = encryptedBytes.sublist(encryptedBytes.length - 16);

    final publicKey = RSAUtils.parsePublicKeyFromPem(publicRsaKey);
    final rsaCipher = OAEPEncoding(RSAEngine());
    rsaCipher.init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
    
    final encryptedKey = rsaCipher.process(aesKey);

    final data = '${base64.encode(nonce)}.${base64.encode(authTag)}.${base64.encode(encryptedData)}';
    
    print('Повідомлення зашифровано');
    return {
      'key': base64.encode(encryptedKey),
      'data': data,
    };
  }

  static String decryptMessage(Map<String, String> encryptedData) {
    final privateKey = File('private_key.pem').readAsStringSync();
    final parsedPrivateKey = RSAUtils.parsePrivateKeyFromPem(privateKey);

    final rsaCipher = OAEPEncoding(RSAEngine());
    rsaCipher.init(false, PrivateKeyParameter<RSAPrivateKey>(parsedPrivateKey));
    
    final encryptedKeyBytes = base64.decode(encryptedData['key']!);
    final aesKey = rsaCipher.process(encryptedKeyBytes);

    final parts = encryptedData['data']!.split('.');
    if (parts.length != 3) {
      throw Exception('Неправильний формат зашифрованих даних');
    }

    final nonce = base64.decode(parts[0]);
    final authTag = base64.decode(parts[1]);
    final encryptedMessage = base64.decode(parts[2]);

    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(KeyParameter(aesKey), 128, nonce, Uint8List(0));
    cipher.init(false, params);

    final encryptedWithTag = Uint8List.fromList([...encryptedMessage, ...authTag]);
    final decryptedBytes = cipher.process(encryptedWithTag);
    
    print('Повідомлення розшифровано');
    return utf8.decode(decryptedBytes);
  }
}