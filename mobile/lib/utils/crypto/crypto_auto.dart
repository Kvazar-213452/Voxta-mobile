import 'crypto_app.dart';
import 'utils.dart';
import '../../models/storage_key.dart';
import 'dart:convert';

Future<Map<String, dynamic>> decrypted_auto(Map<String, dynamic> data) async {
  final keyPair = await getOrCreateKeyPair();

  final jsonResponse = data;
  final decrypted = await decryptServerResponse(jsonResponse, keyPair.privateKey);
  
  return jsonDecode(decrypted);
}

Future<Map<String, dynamic>> encrypt_auto(Map<String, dynamic> data) async {
  final keyPair = await getOrCreateKeyPair();
  final publicKeyPem = encodePublicKeyToPemPKCS1(keyPair.publicKey);

  final dataToEncrypt = jsonEncode(data);

  final serverPublicKeyPem = await getServerPublicKey();
  final encrypted = await encryptMessage(dataToEncrypt, serverPublicKeyPem);

  return {
    'data': {
      'data': encrypted['data'],
      'key': encrypted['key'],
    },
    'key': publicKeyPem,
    'type': 'mobile',
  };
}

