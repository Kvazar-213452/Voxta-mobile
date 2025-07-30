import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'storage_service.dart';
import 'interface/user.dart';
import 'dart:convert';

final FlutterSecureStorage secureStorage = getSecureStorage();

Future<void> saveUserStorage(UserModel user) async {
  try {
    await secureStorage.write(key: "userData", value: jsonEncode(user.toJson()));
  } catch (e) {
    print('erro save user in secure storage: $e');
  }
}

Future<UserModel?> getUserStorage() async {
  try {
    final value = await secureStorage.read(key: "userData");

    if (value == null) return null;

    final Map<String, dynamic> json = jsonDecode(value);
    return UserModel.fromJson(json);
  } catch (e) {
    print('error read user secure storage: $e');
    return null;
  }
}

// ? ======== JWT save func ========

Future<void> saveJWTStorage(String jwt) async {
  try {
    print(jwt);
    await secureStorage.write(key: "jwtData", value: jwt);
  } catch (e) {
    print('erro save jwt in secure storage: $e');
  }
}

Future<String?> getJWTStorage() async {
  try {
    final value = await secureStorage.read(key: "jwtData");

    if (value == null) return null;

    return value;
  } catch (e) {
    print('errror renad jwt in secure storage: $e');
    return null;
  }
}
