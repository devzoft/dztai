import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureKeyService {
  static const _key = 'openrouter_api_key';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveKey(String key) => _storage.write(key: _key, value: key);
  Future<String?> getKey() => _storage.read(key: _key);
  Future<void> deleteKey() => _storage.delete(key: _key);
  Future<bool> hasKey() async => (await getKey()) != null;
}
