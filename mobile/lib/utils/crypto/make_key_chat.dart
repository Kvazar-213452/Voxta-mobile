import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:asn1lib/asn1lib.dart';

/// Клас для роботи з RSA шифруванням
class RSACrypto {
  /// Генерує пару RSA ключів (публічний та приватний)
  /// [keySize] - розмір ключа в бітах (за замовчуванням 2048, рекомендовано 2048 або 4096)
  static Future<Map<String, String>> generateKeyPair({
    int keySize = 2048,
  }) async {
    try {
      final secureRandom = _getSecureRandom();

      final keyGen =
          RSAKeyGenerator()..init(
            ParametersWithRandom(
              RSAKeyGeneratorParameters(BigInt.from(65537), keySize, 64),
              secureRandom,
            ),
          );

      final pair = keyGen.generateKeyPair();
      final publicKey = pair.publicKey as RSAPublicKey;
      final privateKey = pair.privateKey as RSAPrivateKey;

      final publicKeyBase64 = _encodePublicKeyToBase64(publicKey);
      final privateKeyBase64 = _encodePrivateKeyToBase64(privateKey);

      print('RSA key pair generated successfully (size: $keySize bits)');

      return {'public': publicKeyBase64, 'private': privateKeyBase64};
    } catch (e) {
      print('Failed to generate RSA key pair: $e');
      rethrow;
    }
  }

  /// Шифрує дані публічним ключем
  static String encrypt(String plainText, String publicKeyBase64) {
    try {
      final publicKey = _parsePublicKeyFromBase64(publicKeyBase64);
      final cipher =
          RSAEngine()..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

      final dataToEncrypt = Uint8List.fromList(utf8.encode(plainText));
      final encrypted = cipher.process(dataToEncrypt);

      return base64.encode(encrypted);
    } catch (e) {
      print('Failed to encrypt: $e');
      rethrow;
    }
  }

  /// Розшифровує дані приватним ключем
  static String decrypt(String encryptedBase64, String privateKeyBase64) {
    try {
      final privateKey = _parsePrivateKeyFromBase64(privateKeyBase64);
      final cipher =
          RSAEngine()
            ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));

      final encryptedData = base64.decode(encryptedBase64);
      final decrypted = cipher.process(Uint8List.fromList(encryptedData));

      return utf8.decode(decrypted);
    } catch (e) {
      print('Failed to decrypt: $e');
      rethrow;
    }
  }

  // ==================== PRIVATE HELPER METHODS ====================

  static SecureRandom _getSecureRandom() {
    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  static String _encodePublicKeyToBase64(RSAPublicKey publicKey) {
    var algorithmSeq = ASN1Sequence();
    var algorithmAsn1Obj = ASN1Object.fromBytes(
      Uint8List.fromList([
        0x6,
        0x9,
        0x2a,
        0x86,
        0x48,
        0x86,
        0xf7,
        0xd,
        0x1,
        0x1,
        0x1,
      ]),
    );
    var paramsAsn1Obj = ASN1Object.fromBytes(Uint8List.fromList([0x5, 0x0]));
    algorithmSeq.add(algorithmAsn1Obj);
    algorithmSeq.add(paramsAsn1Obj);

    var publicKeySeq = ASN1Sequence();
    publicKeySeq.add(ASN1Integer(publicKey.modulus!));
    publicKeySeq.add(ASN1Integer(publicKey.exponent!));
    var publicKeySeqBitString = ASN1BitString(
      Uint8List.fromList(publicKeySeq.encodedBytes),
    );

    var topLevelSeq = ASN1Sequence();
    topLevelSeq.add(algorithmSeq);
    topLevelSeq.add(publicKeySeqBitString);

    return base64.encode(topLevelSeq.encodedBytes);
  }

  static String _encodePrivateKeyToBase64(RSAPrivateKey privateKey) {
    var topLevelSeq = ASN1Sequence();

    topLevelSeq.add(ASN1Integer(BigInt.from(0))); // version
    topLevelSeq.add(ASN1Integer(privateKey.n!)); // modulus
    topLevelSeq.add(ASN1Integer(privateKey.exponent!)); // publicExponent
    topLevelSeq.add(
      ASN1Integer(privateKey.privateExponent!),
    ); // privateExponent
    topLevelSeq.add(ASN1Integer(privateKey.p!)); // prime1
    topLevelSeq.add(ASN1Integer(privateKey.q!)); // prime2
    topLevelSeq.add(
      ASN1Integer(privateKey.privateExponent! % (privateKey.p! - BigInt.one)),
    ); // exponent1
    topLevelSeq.add(
      ASN1Integer(privateKey.privateExponent! % (privateKey.q! - BigInt.one)),
    ); // exponent2
    topLevelSeq.add(
      ASN1Integer(privateKey.q!.modInverse(privateKey.p!)),
    ); // coefficient

    return base64.encode(topLevelSeq.encodedBytes);
  }

  static RSAPublicKey _parsePublicKeyFromBase64(String base64Key) {
    final bytes = base64.decode(base64Key);

    var asn1Parser = ASN1Parser(Uint8List.fromList(bytes));
    var topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
    var publicKeyBitString = topLevelSeq.elements![1] as ASN1BitString;

    var publicKeyAsn = ASN1Parser(publicKeyBitString.valueBytes());
    var publicKeySeq = publicKeyAsn.nextObject() as ASN1Sequence;

    var modulus = (publicKeySeq.elements![0] as ASN1Integer).valueAsBigInteger;
    var exponent = (publicKeySeq.elements![1] as ASN1Integer).valueAsBigInteger;

    return RSAPublicKey(modulus, exponent);
  }

  static RSAPrivateKey _parsePrivateKeyFromBase64(String base64Key) {
    final bytes = base64.decode(base64Key);

    var asn1Parser = ASN1Parser(Uint8List.fromList(bytes));
    var topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;

    var modulus = (topLevelSeq.elements![1] as ASN1Integer).valueAsBigInteger;
    var privateExponent =
        (topLevelSeq.elements![3] as ASN1Integer).valueAsBigInteger;
    var p = (topLevelSeq.elements![4] as ASN1Integer).valueAsBigInteger;
    var q = (topLevelSeq.elements![5] as ASN1Integer).valueAsBigInteger;

    return RSAPrivateKey(modulus, privateExponent, p, q);
  }
}