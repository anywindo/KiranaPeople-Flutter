import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../config/api_config.dart';
import '../storage/secure_storage_service.dart';
import 'api_exception.dart';

class ApiClient {
  static VoidCallback? onUnauthorized;

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

    _dio.options.connectTimeout = const Duration(seconds: 20);
    _dio.options.receiveTimeout = const Duration(seconds: 20);
    _dio.options.sendTimeout = const Duration(seconds: 25);
    _dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Construct explicit full URL so Dio doesn't strip baseUrl subpath (e.g. /api/v1)
          if (!options.path.startsWith('http://') &&
              !options.path.startsWith('https://')) {
            final currentBaseUrl = await ApiConfig.getBaseUrl();
            options.path = _resolveFullPath(currentBaseUrl, options.path);
          }

          // Add Bearer Token if present
          final token = await _storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          developer.log(
            '[API Request] ${options.method} ${options.path}',
            name: 'ApiClient',
          );
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
          if (kDebugMode) {
            developer.log(
              '[API Error] ${e.requestOptions.method} $uri -> ${e.type}: ${e.message} (status: ${e.response?.statusCode})',
              name: 'ApiClient',
              error: e,
            );
            debugPrint(
              '[ApiClient Error] ${e.requestOptions.method} $uri -> ${e.type}: ${e.message} (status: ${e.response?.statusCode}) error: ${e.error}',
            );
          }

          final response = e.response;
          String message =
              'A network error occurred. Please check your internet connection.';
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
                    data['message'] ??
                    data['meta']?['message'] ??
                    data['error'];
                if (m != null && m.toString().isNotEmpty) {
                  message = m.toString();
                  hasCustomMessage = true;
                } else {
                  message =
                      'Failed to process request (${response.statusCode})';
                }
              }
            } else if (data is String && data.isNotEmpty) {
              message = data;
              hasCustomMessage = true;
            }

            // Fallback status messages if no specific custom message was provided
            if (response.statusCode == 401) {
              if (!hasCustomMessage) {
                message = 'Invalid credentials or session has expired.';
              }
              if (!e.requestOptions.path.contains('/login')) {
                onUnauthorized?.call();
              }
            } else if (response.statusCode == 429) {
              if (!hasCustomMessage) {
                message =
                    'Too many requests (Rate limit). Please wait a moment.';
              }
            } else if (response.statusCode == 403) {
              if (!hasCustomMessage) {
                message = 'You do not have permission to access this resource.';
              }
            } else if (response.statusCode == 404) {
              if (!hasCustomMessage) {
                message = 'Requested resource not found.';
              }
            } else if (response.statusCode == 422) {
              if (!hasCustomMessage) {
                message = 'Invalid input data.';
              }
            } else if (response.statusCode != null &&
                response.statusCode! >= 500) {
              if (!hasCustomMessage) {
                message = 'An internal server error occurred.';
              }
            }
          } else if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout) {
            message = 'Connection to server timed out. Please try again.';
          } else if (e.type == DioExceptionType.connectionError ||
              e.error is SocketException ||
              e.error is HandshakeException ||
              e.error is TlsException) {
            message = 'Failed to connect to server. Please check your internet connection.';
          } else {
            message = 'Failed to communicate with server. Please try again.';
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
        options: Options(contentType: 'multipart/form-data'),
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
