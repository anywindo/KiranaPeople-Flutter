import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../config/api_config.dart';
import '../storage/secure_storage_service.dart';
import 'api_exception.dart';
import 'api_interceptor.dart';

export 'api_error_localizer.dart';
export 'api_exception.dart';
export 'api_interceptor.dart';

class ApiClient {
  static VoidCallback? onUnauthorized;

  /// Callback notified whenever an API request determines backend server reachability.
  /// `isReachable = true` when server responds (2xx, 3xx, 4xx).
  /// `isReachable = false` on network error, timeouts, or 5xx server errors.
  static void Function(bool isReachable)? onServerReachabilityChanged;

  final Dio _dio;
  final SecureStorageService _storage;

  ApiClient({Dio? dio, SecureStorageService? storage})
    : _dio = dio ?? Dio(),
      _storage = storage ?? SecureStorageService() {
    // Configure HttpClient to support local HTTPS development safely without exposing production to MitM
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) {
              return shouldAcceptBadCertificate(host);
            };
        return client;
      },
    );

    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
    _dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    _dio.interceptors.add(
      ApiInterceptor(
        storage: _storage,
        onUnauthorized: () => onUnauthorized?.call(),
        onServerReachabilityChanged: (reachable) =>
            onServerReachabilityChanged?.call(reachable),
      ),
    );
  }

  /// SECURITY: Validates whether an invalid/self-signed certificate should be accepted.
  /// In release builds (production), invalid certificates are NEVER accepted to prevent MitM attacks.
  /// In debug mode, self-signed certs are restricted strictly to recognized local development hosts.
  @visibleForTesting
  static bool shouldAcceptBadCertificate(
    String host, {
    bool isDebug = kDebugMode,
  }) {
    if (!isDebug) return false;
    final isLocalDev =
        host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '10.0.2.2' ||
        host.endsWith('.test') ||
        host.startsWith('192.168.') ||
        host.startsWith('10.');
    return isLocalDev;
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
      throw ApiException(
        message: e.message ?? 'Terjadi kesalahan tidak terduga.',
      );
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
      throw ApiException(
        message: e.message ?? 'Terjadi kesalahan tidak terduga.',
      );
    }
  }

  Future<Response> postMultipart(
    String path, {
    required FormData formData,
    ProgressCallback? onSendProgress,
    Duration? sendTimeout,
    Duration? receiveTimeout,
  }) async {
    try {
      return await _dio.post(
        path,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: sendTimeout ?? const Duration(seconds: 60),
          receiveTimeout: receiveTimeout ?? const Duration(seconds: 60),
        ),
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(
        message: e.message ?? 'Terjadi kesalahan tidak terduga.',
      );
    }
  }

  /// Checks actual backend connectivity by querying the base health API endpoint with a short timeout.
  /// Returns `true` if backend responds (HTTP status < 500); `false` on timeout, connection error, or 5xx.
  Future<bool> checkServerHealth({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final healthDio = Dio(
        BaseOptions(
          connectTimeout: timeout,
          receiveTimeout: timeout,
          sendTimeout: timeout,
          validateStatus: (status) => status != null,
        ),
      );
      healthDio.httpClientAdapter = _dio.httpClientAdapter;

      final response = await healthDio.get(baseUrl);
      final isHealthy =
          response.statusCode != null && response.statusCode! < 500;
      return isHealthy;
    } catch (e) {
      developer.log('[ApiClient] Health check failed: $e', name: 'ApiClient');
      return false;
    }
  }
}
