import 'dart:io';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../storage/secure_storage_service.dart';
import 'api_exception.dart';

class ApiClient {
  final Dio _dio;
  final SecureStorageService _storage;

  ApiClient({
    Dio? dio,
    SecureStorageService? storage,
  })  : _dio = dio ?? Dio(),
        _storage = storage ?? SecureStorageService() {
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Dynamically set Base URL if not set on request
          final currentBaseUrl = await ApiConfig.getBaseUrl();
          options.baseUrl = currentBaseUrl;

          // Add Bearer Token if present
          final token = await _storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onError: (DioException e, handler) {
          final response = e.response;
          String message = 'Terjadi kesalahan jaringan. Periksa koneksi Anda.';
          dynamic errors;

          if (response != null) {
            final data = response.data;
            if (data is Map<String, dynamic>) {
              message = data['message'] ??
                  data['error'] ??
                  'Gagal memproses permintaan (${response.statusCode})';
              errors = data['errors'];
            } else if (response.statusCode == 401) {
              message = 'Sesi telah berakhir. Silakan login kembali.';
            } else if (response.statusCode == 403) {
              message = 'Anda tidak memiliki akses ke fitur ini.';
            } else if (response.statusCode == 404) {
              message = 'Layanan atau data tidak ditemukan.';
            } else if (response.statusCode == 422) {
              message = 'Data input tidak valid.';
            } else if (response.statusCode != null && response.statusCode! >= 500) {
              message = 'Terjadi kesalahan pada server backend.';
            }
          } else if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout) {
            message = 'Koneksi ke server timeout. Silakan coba lagi.';
          } else if (e.error is SocketException) {
            message = 'Gagal terhubung ke server. Pastikan URL server benar dan aktif.';
          }

          final customException = ApiException(
            message: message,
            statusCode: response?.statusCode,
            errors: errors,
          );

          return handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              response: e.response,
              type: e.type,
              error: customException,
            ),
          );
        },
      ),
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Unknown error');
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Unknown error');
    }
  }

  Future<Response> postMultipart(
    String path, {
    required FormData formData,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      return await _dio.post(
        path,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Unknown error');
    }
  }
}
