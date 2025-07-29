import 'package:flutter_secure_storage/flutter_secure_storage.dart';

FlutterSecureStorage? _secureStorage;

/// Ініціалізація (викликати один раз, наприклад, у main)
void initSecureStorage() {
  _secureStorage ??= const FlutterSecureStorage();
}

/// Отримати доступ до ініціалізованого сховища
FlutterSecureStorage getSecureStorage() {
  if (_secureStorage == null) {
    throw Exception('SecureStorage не ініціалізовано. Виклич initSecureStorage() спочатку.');
  }
  return _secureStorage!;
}
