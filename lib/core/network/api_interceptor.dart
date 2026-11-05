import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../storage/secure_storage_service.dart';
import 'api_error_localizer.dart';
import 'api_exception.dart';

class ApiInterceptor extends Interceptor {
  final SecureStorageService storage;
  final VoidCallback? onUnauthorized;
  final void Function(bool isReachable)? onServerReachabilityChanged;

  ApiInterceptor({
    required this.storage,
    this.onUnauthorized,
    this.onServerReachabilityChanged,
  });

  static String resolveFullPath(String baseUrl, String path) {
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

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Construct explicit full URL so Dio doesn't strip baseUrl subpath (e.g. /api/v1)
    if (!options.path.startsWith('http://') &&
        !options.path.startsWith('https://')) {
      final currentBaseUrl = await ApiConfig.getBaseUrl();
      options.path = resolveFullPath(currentBaseUrl, options.path);
    }

    // Add Bearer Token if present
    final token = await storage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    developer.log(
      '[API Request] ${options.method} ${options.path}',
      name: 'ApiClient',
    );
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    developer.log(
      '[API Response] ${response.requestOptions.method} ${response.requestOptions.path} (${response.statusCode})',
      name: 'ApiClient',
    );
    onServerReachabilityChanged?.call(true);
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final uri = err.requestOptions.uri;
    if (kDebugMode) {
      developer.log(
        '[API Error] ${err.requestOptions.method} $uri -> ${err.type}: ${err.message} (status: ${err.response?.statusCode})',
        name: 'ApiClient',
        error: err,
      );
      debugPrint(
        '[ApiClient Error] ${err.requestOptions.method} $uri -> ${err.type}: ${err.message} (status: ${err.response?.statusCode}) error: ${err.error}',
      );
    }

    final response = err.response;
    if (response != null &&
        response.statusCode != null &&
        response.statusCode! >= 500) {
      // Server error (500, 502, 503, 504) -> server down/failing
      onServerReachabilityChanged?.call(false);
    } else if (response != null &&
        response.statusCode != null &&
        response.statusCode! < 500) {
      // Client error (400, 401, 403, 404, 422) -> server responded and is reachable
      onServerReachabilityChanged?.call(true);
    } else if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError ||
        err.error is SocketException ||
        err.error is HandshakeException ||
        err.error is TlsException ||
        err.error is HttpException) {
      // Network connection failure or timeout -> server unreachable
      onServerReachabilityChanged?.call(false);
    }
    String message =
        'Terjadi kesalahan koneksi. Periksa koneksi internet Anda.';
    dynamic errors;

    if (response != null) {
      final data = response.data;
      bool hasCustomMessage = false;

      // Extract message and validation errors from JSON response if available
      if (data is Map) {
        errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final firstVal = errors.values.first;
          if (firstVal is List && firstVal.isNotEmpty) {
            message = firstVal.first.toString();
            hasCustomMessage = true;
          } else if (firstVal is String && firstVal.isNotEmpty) {
            message = firstVal;
            hasCustomMessage = true;
          } else {
            final m = data['meta']?['message'] ?? data['message'];
            if (m != null && m.toString().isNotEmpty) {
              message = m.toString();
              hasCustomMessage = true;
            }
          }
        } else {
          final m =
              data['message'] ?? data['meta']?['message'] ?? data['error'];
          if (m != null && m.toString().isNotEmpty) {
            message = m.toString();
            hasCustomMessage = true;
          } else {
            message = 'Gagal memproses permintaan (${response.statusCode})';
          }
        }
      } else if (data is String && data.isNotEmpty) {
        message = data;
        hasCustomMessage = true;
      }

      // Fallback status messages if no specific custom message was provided
      if (response.statusCode == 401) {
        if (!hasCustomMessage) {
          message = 'Sesi Anda telah berakhir atau identitas login salah.';
        }
        if (!err.requestOptions.path.contains('/login')) {
          onUnauthorized?.call();
        }
      } else if (response.statusCode == 429) {
        if (!hasCustomMessage) {
          message = 'Terlalu banyak permintaan. Silakan tunggu beberapa saat.';
        }
      } else if (response.statusCode == 403) {
        if (!hasCustomMessage) {
          message = 'Anda tidak memiliki izin untuk mengakses fitur ini.';
        }
      } else if (response.statusCode == 404) {
        if (!hasCustomMessage) {
          message = 'Data yang diminta tidak ditemukan.';
        }
      } else if (response.statusCode == 422) {
        if (!hasCustomMessage) {
          message = 'Data yang dimasukkan tidak valid.';
        }
      } else if (response.statusCode != null && response.statusCode! >= 500) {
        if (!hasCustomMessage) {
          message = 'Terjadi kesalahan pada server. Silakan coba lagi nanti.';
        }
      }
    } else if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      message = 'Koneksi ke server terputus (waktu habis). Silakan coba lagi.';
    } else if (err.type == DioExceptionType.connectionError ||
        err.error is SocketException ||
        err.error is HandshakeException ||
        err.error is TlsException) {
      message = 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
    } else {
      message = 'Terjadi gangguan saat berkomunikasi dengan server. Silakan coba lagi.';
    }

    final customException = ApiException(
      message: ApiErrorLocalizer.localize(message),
      statusCode: response?.statusCode,
      errors: errors,
    );

    return handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: customException,
      ),
    );
  }
}
