import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/core/config/api_config.dart';
import 'package:kirana_people/core/network/api_client.dart';
import 'package:kirana_people/core/storage/secure_storage_service.dart';

class _TestErrorHandler extends ErrorInterceptorHandler {
  DioException? rejectedError;

  @override
  void reject(DioException error, [bool trueCall = false]) {
    rejectedError = error;
  }
}

void main() {
  group('ApiConfig Tests', () {
    test('ApiConfig is fixed to app.kiranapeople.com', () async {
      expect(
        ApiConfig.defaultBaseUrl,
        equals('https://app.kiranapeople.com/api/v1'),
      );
      expect(ApiConfig.cachedHostOrigin, equals('https://app.kiranapeople.com'));
      expect(
        await ApiConfig.getBaseUrl(),
        equals('https://app.kiranapeople.com/api/v1'),
      );
      expect(ApiConfig.getHostOrigin(), equals('https://app.kiranapeople.com'));
    });
  });

  group('ApiClient SSL / TLS Certificate Validation Security Tests', () {
    test('Release mode strictly rejects invalid certificates for all hosts (prevents MitM)', () {
      const releaseMode = false;

      // Remote cloud / production endpoints
      expect(
        ApiClient.shouldAcceptBadCertificate(
          'app.kiranapeople.com',
          isDebug: releaseMode,
        ),
        isFalse,
      );
      expect(
        ApiClient.shouldAcceptBadCertificate(
          'api.company.com',
          isDebug: releaseMode,
        ),
        isFalse,
      );

      // Private LAN / local hosts must NOT bypass TLS verification in release
      expect(
        ApiClient.shouldAcceptBadCertificate(
          '192.168.1.11',
          isDebug: releaseMode,
        ),
        isFalse,
      );
      expect(
        ApiClient.shouldAcceptBadCertificate('10.0.0.1', isDebug: releaseMode),
        isFalse,
      );
      expect(
        ApiClient.shouldAcceptBadCertificate('localhost', isDebug: releaseMode),
        isFalse,
      );
      expect(
        ApiClient.shouldAcceptBadCertificate('127.0.0.1', isDebug: releaseMode),
        isFalse,
      );
      expect(
        ApiClient.shouldAcceptBadCertificate('10.0.2.2', isDebug: releaseMode),
        isFalse,
      );
      expect(
        ApiClient.shouldAcceptBadCertificate(
          'terriblenight.test',
          isDebug: releaseMode,
        ),
        isFalse,
      );
    });

    test(
      'Debug mode rejects invalid certificates for remote / public hosts',
      () {
        const debugMode = true;

        // Remote production / third-party endpoints must still enforce valid certificates in debug mode
        expect(
          ApiClient.shouldAcceptBadCertificate(
            'app.kiranapeople.com',
            isDebug: debugMode,
          ),
          isFalse,
        );
        expect(
          ApiClient.shouldAcceptBadCertificate(
            'google.com',
            isDebug: debugMode,
          ),
          isFalse,
        );
        expect(
          ApiClient.shouldAcceptBadCertificate(
            'api.example.org',
            isDebug: debugMode,
          ),
          isFalse,
        );
      },
    );

    test('Debug mode allows self-signed certificates only for local development environments', () {
      const debugMode = true;

      expect(
        ApiClient.shouldAcceptBadCertificate('localhost', isDebug: debugMode),
        isTrue,
      );
      expect(
        ApiClient.shouldAcceptBadCertificate('127.0.0.1', isDebug: debugMode),
        isTrue,
      );
      expect(
        ApiClient.shouldAcceptBadCertificate('10.0.2.2', isDebug: debugMode),
        isTrue,
      );
      expect(
        ApiClient.shouldAcceptBadCertificate(
          '192.168.1.50',
          isDebug: debugMode,
        ),
        isTrue,
      );
      expect(
        ApiClient.shouldAcceptBadCertificate('10.1.2.3', isDebug: debugMode),
        isTrue,
      );
      expect(
        ApiClient.shouldAcceptBadCertificate(
          'terriblenight.test',
          isDebug: debugMode,
        ),
        isTrue,
      );
    });
  });

  group('Gateway Error Handling and HTML Sanitization Tests', () {
    test('ApiErrorLocalizer filters out raw HTML error responses from proxies/gateways', () {
      const rawHtml502 = '<!DOCTYPE html>\n<html lang="en">\n<head><title>502</title></head><body>Bad Gateway</body></html>';
      final localized = ApiErrorLocalizer.localize(rawHtml502);

      expect(localized, isNot(contains('<!DOCTYPE')));
      expect(localized, isNot(contains('<html')));
      expect(localized, equals('Server sedang tidak dapat dijangkau. Silakan coba beberapa saat lagi.'));
    });

    test('ApiInterceptor converts HTML 502/503/504 responses to clean user-friendly messages', () {
      final interceptor = ApiInterceptor(storage: SecureStorageService());
      final requestOptions = RequestOptions(path: '/auth/login');

      // Test 502 Bad Gateway with HTML body
      final handler502 = _TestErrorHandler();
      interceptor.onError(
        DioException(
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 502,
            data: '<!DOCTYPE html><html><title>502</title></html>',
          ),
          type: DioExceptionType.badResponse,
        ),
        handler502,
      );

      expect(handler502.rejectedError, isNotNull);
      final apiError502 = handler502.rejectedError!.error as ApiException;
      expect(apiError502.message, contains('502 Bad Gateway'));
      expect(apiError502.message, isNot(contains('<!DOCTYPE')));

      // Test 503 Service Unavailable
      final handler503 = _TestErrorHandler();
      interceptor.onError(
        DioException(
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 503,
            data: '<html>503 Service Unavailable</html>',
          ),
          type: DioExceptionType.badResponse,
        ),
        handler503,
      );

      expect(handler503.rejectedError, isNotNull);
      final apiError503 = handler503.rejectedError!.error as ApiException;
      expect(apiError503.message, contains('503 Service Unavailable'));
      expect(apiError503.message, isNot(contains('<html>')));
    });
  });
}
