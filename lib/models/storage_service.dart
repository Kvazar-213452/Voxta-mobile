import 'package:flutter_secure_storage/flutter_secure_storage.dart';

FlutterSecureStorage? _secureStorage;

void initSecureStorage() {
  _secureStorage ??= const FlutterSecureStorage();
}

FlutterSecureStorage getSecureStorage() {
  if (_secureStorage == null) {
    throw Exception('SecureStorage not init');
  }
  return _secureStorage!;
}
