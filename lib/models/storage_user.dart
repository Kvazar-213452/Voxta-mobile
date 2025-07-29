import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'storage_service.dart';

final FlutterSecureStorage secureStorage = getSecureStorage();

Future<void> saveToSecureStorage(String key, String value) async {
  try {
    await secureStorage.write(key: key, value: value);
    print('Значення збережено успішно');
  } catch (e) {
    print('Помилка при збереженні в secure storage: $e');
  }
}

Future<String?> readFromSecureStorage(String key) async {
  try {
    final value = await secureStorage.read(key: key);
    print('Отримано значення: $value');
    return value;
  } catch (e) {
    print('Помилка при читанні з secure storage: $e');
    return null;
  }
}
