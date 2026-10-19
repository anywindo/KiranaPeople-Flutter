import 'dart:convert';
import 'dart:io';
import '../models/user_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/storage/secure_storage_service.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  AuthRepository({
    ApiClient? apiClient,
    SecureStorageService? storage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final deviceName = Platform.isAndroid ? 'KiranaPeople-Android' : 'KiranaPeople-iOS';

    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: {
        'email': email.trim(),
        'password': password,
        'device_name': deviceName,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      // Backend may return token in data['token'] or data['data']['token']
      final token = data['token'] ?? data['data']?['token'];
      if (token != null) {
        await _storage.saveToken(token.toString());
      }

      // User payload
      final userJson = data['user'] ?? data['data']?['user'] ?? data['data'];
      if (userJson is Map<String, dynamic>) {
        final user = UserModel.fromJson(userJson);
        await _storage.saveUserJson(jsonEncode(user.toJson()));
        return user;
      }
    }

    throw Exception('Format respon login tidak valid.');
  }

  Future<UserModel> getProfile() async {
    final response = await _apiClient.get(ApiEndpoints.profile);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final userJson = data['data'] ?? data['user'] ?? data;
      if (userJson is Map<String, dynamic>) {
        final user = UserModel.fromJson(userJson);
        await _storage.saveUserJson(jsonEncode(user.toJson()));
        return user;
      }
    }
    throw Exception('Gagal memuat profil pengguna.');
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _apiClient.post(
      ApiEndpoints.changePassword,
      data: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': confirmPassword,
      },
    );
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (_) {
      // Ignore network failure on logout
    } finally {
      await _storage.clearAll();
    }
  }

  Future<UserModel?> getCachedUser() async {
    final userJsonStr = await _storage.getUserJson();
    if (userJsonStr != null && userJsonStr.isNotEmpty) {
      try {
        final map = jsonDecode(userJsonStr) as Map<String, dynamic>;
        return UserModel.fromJson(map);
      } catch (_) {}
    }
    return null;
  }

  Future<bool> hasValidToken() async {
    final token = await _storage.getToken();
    return token != null && token.isNotEmpty;
  }
}
