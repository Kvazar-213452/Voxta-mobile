import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/crypto/crypto_app.dart';
import '../models/storage_key.dart';
import '../config.dart';
import '../models/storage_user.dart';
import '../models/interface/user.dart';
import '../utils/crypto/utils.dart';

Future<bool> getInfoToJwt(String id, String jwt) async {
  try {
    final keyPair = await getOrCreateKeyPair();
    final publicKeyPem = encodePublicKeyToPemPKCS1(keyPair.publicKey);

    final dataToEncrypt = jsonEncode({
      'jwt': jwt,
      'id': id,
    });

    final serverPublicKeyPem = await getServerPublicKey();

    final encrypted = await encryptMessage(dataToEncrypt, serverPublicKeyPem);

    final response = await http.post(
      Uri.parse('${Config.URL_SERVICES_AUNTIFICATION}/get_info_to_jwt'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'data': {
          'data': encrypted['data'],
          'key': encrypted['key'],
        },
        'key': publicKeyPem,
        'type': 'mobile',
      }),
    );

    if (response.statusCode != 200) {
      print('HTTP error: ${response.statusCode}');
      return false;
    }

    final jsonResponse = jsonDecode(response.body);
    final decrypted = await decryptServerResponse(jsonResponse, keyPair.privateKey);
    
    final data = jsonDecode(decrypted);
    if (jsonResponse['code'] == 0) {
      print('Invalid response code: ${data['code']}');
      return false;
    }

    final userModel = UserModel.fromJson(data);

    await saveUserStorage(userModel);

    return true;
  } catch (e) {
    print('Error in getInfoToJwt: $e');
    return false;
  }
}
