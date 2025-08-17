import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'storage_service.dart';

final FlutterSecureStorage secureStorage = getSecureStorage();

Future<void> savePaswStorage(int pasw) async {
  try {
    await secureStorage.write(
      key: "paswKey",
      value: pasw.toString(),
    );
  } catch (e) {
    print('error save pasw in secure storage: $e');
  }
}

Future<int?> getPaswStorage() async {
  try {
    final value = await secureStorage.read(key: "paswKey");

    if (value == null) return null;

    return int.tryParse(value);
  } catch (e) {
    print('error read pasw in secure storage: $e');
    return null;
  }
}
