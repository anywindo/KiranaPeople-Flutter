import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/core/config/api_config.dart';
import 'package:kirana_people/core/network/api_client.dart';

void main() {
  group('ApiConfig Tests', () {
    test('ApiConfig is fixed to kp.krtekstile.com', () async {
      expect(
        ApiConfig.defaultBaseUrl,
        equals('https://kp.krtekstile.com/api/v1'),
      );
      expect(ApiConfig.cachedHostOrigin, equals('https://kp.krtekstile.com'));
      expect(
        await ApiConfig.getBaseUrl(),
        equals('https://kp.krtekstile.com/api/v1'),
      );
      expect(ApiConfig.getHostOrigin(), equals('https://kp.krtekstile.com'));
    });
  });

  group('ApiClient SSL / TLS Certificate Validation Security Tests', () {
    test('Release mode strictly rejects invalid certificates for all hosts (prevents MitM)', () {
      const releaseMode = false;

      // Remote cloud / production endpoints
      expect(
        ApiClient.shouldAcceptBadCertificate(
          'kp.krtekstile.com',
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
            'kp.krtekstile.com',
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
}
