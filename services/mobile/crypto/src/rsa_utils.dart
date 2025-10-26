import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/asn1.dart';

class RSAUtils {
  static String encodePublicKeyToPkcs1(RSAPublicKey publicKey) {
    final sequence = ASN1Sequence();
    sequence.add(ASN1Integer(publicKey.modulus!));
    sequence.add(ASN1Integer(publicKey.exponent!));
    
    final publicKeyBytes = sequence.encode();
    final base64Key = base64.encode(publicKeyBytes);
    
    return '-----BEGIN RSA PUBLIC KEY-----\n${_formatBase64(base64Key)}\n-----END RSA PUBLIC KEY-----';
  }
 
  static String encodePrivateKeyToPkcs8(RSAPrivateKey privateKey) {
    final rsaPrivateKey = ASN1Sequence();
    rsaPrivateKey.add(ASN1Integer(BigInt.zero));
    rsaPrivateKey.add(ASN1Integer(privateKey.modulus!));
    rsaPrivateKey.add(ASN1Integer(privateKey.exponent!));
    rsaPrivateKey.add(ASN1Integer(privateKey.privateExponent!));
    rsaPrivateKey.add(ASN1Integer(privateKey.p!));
    rsaPrivateKey.add(ASN1Integer(privateKey.q!));
    
    final dp = privateKey.privateExponent! % (privateKey.p! - BigInt.one);
    final dq = privateKey.privateExponent! % (privateKey.q! - BigInt.one);
    final qinv = privateKey.q!.modInverse(privateKey.p!);
    
    rsaPrivateKey.add(ASN1Integer(dp));
    rsaPrivateKey.add(ASN1Integer(dq));
    rsaPrivateKey.add(ASN1Integer(qinv));

    final algorithmSeq = ASN1Sequence();
    algorithmSeq.add(ASN1ObjectIdentifier([1, 2, 840, 113549, 1, 1, 1]));
    algorithmSeq.add(ASN1Null());

    final pkcs8 = ASN1Sequence();
    pkcs8.add(ASN1Integer(BigInt.zero));
    pkcs8.add(algorithmSeq);
    pkcs8.add(ASN1OctetString(octets: rsaPrivateKey.encode()));

    final privateKeyBytes = pkcs8.encode();
    final base64Key = base64.encode(privateKeyBytes);
    
    return '-----BEGIN PRIVATE KEY-----\n${_formatBase64(base64Key)}\n-----END PRIVATE KEY-----';
  }

  static RSAPublicKey parsePublicKeyFromPem(String pem) {
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

  static RSAPrivateKey parsePrivateKeyFromPem(String pem) {
    String keyData = pem
        .replaceAll('-----BEGIN PRIVATE KEY-----', '')
        .replaceAll('-----END PRIVATE KEY-----', '')
        .replaceAll('-----BEGIN RSA PRIVATE KEY-----', '')
        .replaceAll('-----END RSA PRIVATE KEY-----', '')
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .replaceAll(' ', '');

    final keyBytes = base64.decode(keyData);
    final asn1Parser = ASN1Parser(keyBytes);
    final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
    
    if (topLevelSeq.elements!.length >= 3) {
      final privateKeyOctet = topLevelSeq.elements![2] as ASN1OctetString;
      final rsaParser = ASN1Parser(privateKeyOctet.octets!);
      final rsaSeq = rsaParser.nextObject() as ASN1Sequence;
      
      final modulus = (rsaSeq.elements![1] as ASN1Integer).integer!;
      final publicExponent = (rsaSeq.elements![2] as ASN1Integer).integer!;
      final privateExponent = (rsaSeq.elements![3] as ASN1Integer).integer!;
      final p = (rsaSeq.elements![4] as ASN1Integer).integer!;
      final q = (rsaSeq.elements![5] as ASN1Integer).integer!;
      
      return RSAPrivateKey(modulus, privateExponent, p, q);
    }
    
    throw Exception('Неправильний формат приватного ключа');
  }

  static String _formatBase64(String base64) {
    final regex = RegExp(r'.{1,64}');
    return regex.allMatches(base64).map((m) => m.group(0)).join('\n');
  }

  static Uint8List bigIntToBytes(BigInt bigInt) {
    if (bigInt == BigInt.zero) return Uint8List.fromList([0]);
    
    var bytes = <int>[];
    while (bigInt > BigInt.zero) {
      bytes.insert(0, (bigInt & BigInt.from(0xff)).toInt());
      bigInt = bigInt >> 8;
    }
    return Uint8List.fromList(bytes);
  }

  static BigInt bytesToBigInt(Uint8List bytes) {
    BigInt result = BigInt.zero;
    for (int byte in bytes) {
      result = (result << 8) + BigInt.from(byte);
    }
    return result;
  }
}