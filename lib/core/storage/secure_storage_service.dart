import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _keyToken = 'auth_bearer_token';
  static const String _keyUserJson = 'cached_user_json';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  Future<void> saveUserJson(String userJson) async {
    await _storage.write(key: _keyUserJson, value: userJson);
  }

  Future<String?> getUserJson() async {
    return await _storage.read(key: _keyUserJson);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
