import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:asn1lib/asn1lib.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/api.dart' show AsymmetricKeyPair;
import '../utils/crypto/crypto_app.dart';
import '../utils/crypto/generate.dart';

Future<String> _getKeyFilePath(String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  return '${dir.path}/$filename';
}

Future<void> saveKeysToFile(RSAPublicKey publicKey, RSAPrivateKey privateKey) async {
  final pubPath = await _getKeyFilePath('public.pem');
  final privPath = await _getKeyFilePath('private.pem');

  await File(pubPath).writeAsString(encodePublicKeyToPemPKCS1(publicKey));
  await File(privPath).writeAsString(encodePrivateKeyToPemPKCS1(privateKey));
}

Future<bool> doKeysExist() async {
  final pubPath = await _getKeyFilePath('public.pem');
  final privPath = await _getKeyFilePath('private.pem');
  return File(pubPath).existsSync() && File(privPath).existsSync();
}

Future<AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>> getOrCreateKeyPair() async {
  if (await doKeysExist()) {
    final pubPem = await File(await _getKeyFilePath('public.pem')).readAsString();
    final privPem = await File(await _getKeyFilePath('private.pem')).readAsString();

    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
      parsePublicKeyFromPem(pubPem),
      parsePrivateKeyFromPem(privPem),
    );
  }

  final newPair = await generateRSAkeyPair();
  await saveKeysToFile(newPair.publicKey, newPair.privateKey);
  return newPair;
}

String encodePrivateKeyToPemPKCS1(RSAPrivateKey privateKey) {
  final seq = ASN1Sequence()
    ..add(ASN1Integer(BigInt.zero))
    ..add(ASN1Integer(privateKey.n!))
    ..add(ASN1Integer(privateKey.exponent!))
    ..add(ASN1Integer(privateKey.p!))
    ..add(ASN1Integer(privateKey.q!))
    ..add(ASN1Integer(privateKey.exponent! % (privateKey.p! - BigInt.one)))
    ..add(ASN1Integer(privateKey.exponent! % (privateKey.q! - BigInt.one)))
    ..add(ASN1Integer(privateKey.q!.modInverse(privateKey.p!)));

  final base64Str = base64.encode(seq.encodedBytes);
  return '-----BEGIN RSA PRIVATE KEY-----\n${_chunked(base64Str)}\n-----END RSA PRIVATE KEY-----';
}

RSAPrivateKey parsePrivateKeyFromPem(String pemString) {
  final base64Str = pemString
      .split('\n')
      .where((line) => !line.startsWith('-----'))
      .join();
  final bytes = base64.decode(base64Str);

  final parser = ASN1Parser(bytes);
  final seq = parser.nextObject() as ASN1Sequence;

  return RSAPrivateKey(
    (seq.elements[1] as ASN1Integer).valueAsBigInteger!,
    (seq.elements[2] as ASN1Integer).valueAsBigInteger!,
    (seq.elements[3] as ASN1Integer).valueAsBigInteger!,
    (seq.elements[4] as ASN1Integer).valueAsBigInteger!,
  );
}

String _chunked(String str) {
  const chunkSize = 64;
  return List.generate(
    (str.length / chunkSize).ceil(),
    (i) => str.substring(i * chunkSize, (i + 1) * chunkSize > str.length ? str.length : (i + 1) * chunkSize),
  ).join('\n');
}
