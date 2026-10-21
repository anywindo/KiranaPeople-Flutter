import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
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

  Future<UserModel> updateProfile({
    String? phone,
    File? avatarFile,
  }) async {
    final formData = FormData();
    formData.fields.add(const MapEntry('_method', 'PUT'));

    if (phone != null && phone.trim().isNotEmpty) {
      formData.fields.add(MapEntry('phone', phone.trim()));
      formData.fields.add(MapEntry('phone_number', phone.trim()));
    }

    if (avatarFile != null) {
      formData.files.add(
        MapEntry(
          'avatar',
          await MultipartFile.fromFile(
            avatarFile.path,
            filename: 'avatar.jpg',
          ),
        ),
      );
    }

    final response = await _apiClient.post(
      ApiEndpoints.profile,
      data: formData,
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final userJson = data['data'] ?? data['user'] ?? data;
      if (userJson is Map<String, dynamic>) {
        final user = UserModel.fromJson(userJson);
        await _storage.saveUserJson(jsonEncode(user.toJson()));
        return user;
      }
    }
    return await getProfile();
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

  Future<UserModel> updateOnboardingPassword({
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.onboardingPassword,
      data: {
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final userJson = data['data'] ?? data['user'];
      if (userJson is Map<String, dynamic>) {
        final user = UserModel.fromJson(userJson);
        await _storage.saveUserJson(jsonEncode(user.toJson()));
        return user;
      }
    }

    return await getProfile();
  }

  Future<String> requestForgotPasswordOtp(String email) async {
    final response = await _apiClient.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email.trim()},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data['meta']?['message'] ??
          data['message'] ??
          'Jika email Anda terdaftar, instruksi reset kata sandi dan kode OTP telah dikirimkan ke email Anda.';
    }
    return 'Jika email Anda terdaftar, instruksi reset kata sandi dan kode OTP telah dikirimkan ke email Anda.';
  }

  Future<String> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.resetPassword,
      data: {
        'email': email.trim(),
        'otp': otp.trim(),
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data['meta']?['message'] ??
          data['message'] ??
          'Kata sandi Anda berhasil diperbarui. Silakan masuk kembali.';
    }
    return 'Kata sandi Anda berhasil diperbarui. Silakan masuk kembali.';
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (_) {
      // Ignore network failure or already-expired token on logout
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
