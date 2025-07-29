import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'storage_service.dart';
import 'interface/user.dart';
import 'dart:convert';

final FlutterSecureStorage secureStorage = getSecureStorage();

Future<void> saveUserStorage(UserModel user) async {
  try {
    await secureStorage.write(key: "userData", value: jsonEncode(user.toJson()));
    print('Значення збережено успішно');
  } catch (e) {
    print('Помилка при збереженні в secure storage: $e');
  }
}

Future<UserModel?> getUserStorage() async {
  try {
    final value = await secureStorage.read(key: "userData");
    print('Отримано значення: $value');

    if (value == null) return null;

    final Map<String, dynamic> json = jsonDecode(value);
    return UserModel.fromJson(json);
  } catch (e) {
    print('❌ Помилка при читанні з secure storage: $e');
    return null;
  }
}
