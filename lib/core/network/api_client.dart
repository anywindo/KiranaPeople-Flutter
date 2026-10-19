import 'dart:developer' as developer;
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
    _dio.options.connectTimeout = const Duration(seconds: 20);
    _dio.options.receiveTimeout = const Duration(seconds: 20);
    _dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Construct explicit full URL so Dio doesn't strip baseUrl subpath (e.g. /api/v1)
          if (!options.path.startsWith('http://') && !options.path.startsWith('https://')) {
            final currentBaseUrl = await ApiConfig.getBaseUrl();
            options.path = _resolveFullPath(currentBaseUrl, options.path);
          }

          // Add Bearer Token if present
          final token = await _storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          developer.log('[API Request] ${options.method} ${options.path}', name: 'ApiClient');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          developer.log(
            '[API Response] ${response.requestOptions.method} ${response.requestOptions.path} (${response.statusCode})',
            name: 'ApiClient',
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          final uri = e.requestOptions.uri;
          developer.log(
            '[API Error] ${e.requestOptions.method} $uri -> ${e.type}: ${e.message} (status: ${e.response?.statusCode})',
            name: 'ApiClient',
            error: e,
          );

          final response = e.response;
          String message = 'Terjadi kesalahan jaringan. Periksa koneksi Anda.';
          dynamic errors;

          if (response != null) {
            final data = response.data;
            if (response.statusCode == 429) {
              message = 'Terlalu banyak permintaan (Rate limit). Silakan tunggu beberapa menit sebelum meminta kode baru.';
            } else if (data is Map<String, dynamic>) {
              errors = data['errors'];
              if (errors is Map<String, dynamic> && errors.isNotEmpty) {
                final firstVal = errors.values.first;
                if (firstVal is List && firstVal.isNotEmpty) {
                  message = firstVal.first.toString();
                } else if (firstVal is String) {
                  message = firstVal;
                } else {
                  message = data['meta']?['message'] ?? data['message'] ?? 'Input tidak valid.';
                }
              } else {
                message = data['message'] ??
                    data['meta']?['message'] ??
                    data['error'] ??
                    'Gagal memproses permintaan (${response.statusCode})';
              }
            } else if (response.statusCode == 401) {
              message = 'Kredensial salah atau sesi telah berakhir.';
            } else if (response.statusCode == 403) {
              message = 'Anda tidak memiliki akses ke fitur ini.';
            } else if (response.statusCode == 404) {
              message = 'Layanan atau data tidak ditemukan ($uri).';
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
            message = 'Gagal terhubung ke server ($uri). Pastikan URL server benar dan aktif.';
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

  static String _resolveFullPath(String baseUrl, String path) {
    var b = baseUrl.trim();
    while (b.endsWith('/')) {
      b = b.substring(0, b.length - 1);
    }
    var p = path.trim();
    if (!p.startsWith('/')) {
      p = '/$p';
    }
    return '$b$p';
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
