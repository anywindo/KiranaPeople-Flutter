import 'dart:developer' as developer;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
    ),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _keyToken = 'auth_bearer_token';
  static const String _keyUserJson = 'cached_user_json';

  // Fast in-memory token cache to avoid disk reads on every request
  static String? _inMemoryToken;

  Future<void> saveToken(String token) async {
    _inMemoryToken = token;
    try {
      await _storage.write(key: _keyToken, value: token);
    } catch (e) {
      developer.log('[SecureStorage] Error saving token: $e', name: 'SecureStorage');
    }
  }

  Future<String?> getToken() async {
    if (_inMemoryToken != null && _inMemoryToken!.isNotEmpty) {
      return _inMemoryToken;
    }
    try {
      final token = await _storage.read(key: _keyToken);
      _inMemoryToken = token;
      return token;
    } catch (e) {
      developer.log('[SecureStorage] Error reading token: $e', name: 'SecureStorage');
      return _inMemoryToken;
    }
  }

  Future<void> deleteToken() async {
    _inMemoryToken = null;
    try {
      await _storage.delete(key: _keyToken);
    } catch (e) {
      developer.log('[SecureStorage] Error deleting token: $e', name: 'SecureStorage');
    }
  }

  Future<void> saveUserJson(String userJson) async {
    try {
      await _storage.write(key: _keyUserJson, value: userJson);
    } catch (e) {
      developer.log('[SecureStorage] Error saving user JSON: $e', name: 'SecureStorage');
    }
  }

  Future<String?> getUserJson() async {
    try {
      return await _storage.read(key: _keyUserJson);
    } catch (e) {
      developer.log('[SecureStorage] Error reading user JSON: $e', name: 'SecureStorage');
      return null;
    }
  }

  Future<void> clearAll() async {
    _inMemoryToken = null;
    try {
      await _storage.deleteAll();
    } catch (e) {
      developer.log('[SecureStorage] Error clearing all: $e', name: 'SecureStorage');
    }
  }
}
