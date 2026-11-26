import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/core/config/api_config.dart';
import 'package:kirana_people/core/utils/file_download_helper.dart';
import 'package:kirana_people/features/attendance/widgets/photo_preview_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FileDownloadHelper Tests', () {
    test('extractFileName correctly parses original filename and format', () {
      expect(
        FileDownloadHelper.extractFileName(
          'https://app.kiranapeople.com/storage/photos/selfie_123.jpg',
        ),
        equals('selfie_123.jpg'),
      );

      expect(
        FileDownloadHelper.extractFileName(
          'https://app.kiranapeople.com/media/doc_scan.png?token=xyz#preview',
        ),
        equals('doc_scan.png'),
      );

      expect(
        FileDownloadHelper.extractFileName(
          'https://app.kiranapeople.com/media/user%20photo.webp',
        ),
        equals('user photo.webp'),
      );

      expect(
        FileDownloadHelper.extractFileName(
          '/storage/emulated/0/Pictures/captured.jpeg',
        ),
        equals('captured.jpeg'),
      );

      expect(
        FileDownloadHelper.extractFileName('', defaultName: 'fallback.jpg'),
        equals('fallback.jpg'),
      );
    });

    test('resolveFullUrl handles absolute, relative, and local paths', () {
      expect(
        FileDownloadHelper.resolveFullUrl('https://example.com/img.png'),
        equals('https://example.com/img.png'),
      );

      expect(
        FileDownloadHelper.resolveFullUrl('/storage/photos/test.jpg'),
        equals('/storage/photos/test.jpg'),
      );

      expect(
        FileDownloadHelper.resolveFullUrl('/api/v1/media/image.jpg'),
        equals('${ApiConfig.cachedHostOrigin}/api/v1/media/image.jpg'),
      );
    });

    test(
      'sanitizeFileName prevents directory traversal attacks (SEC-12 / CWE-22)',
      () {
        // Relative path traversal attempts
        expect(
          FileDownloadHelper.sanitizeFileName('../../etc/passwd.txt'),
          equals('etc_passwd.txt'),
        );

        expect(
          FileDownloadHelper.sanitizeFileName('..\\..\\windows\\win.ini'),
          equals('windows_win.ini'),
        );

        // Encoded traversal attempts
        expect(
          FileDownloadHelper.sanitizeFileName('%2e%2e%2f%2e%2e%2fevil.pdf'),
          equals('%2e%2e_%2e%2e_evil.pdf'),
        );

        expect(
          FileDownloadHelper.sanitizeFileName('..%2fevil_script.sh'),
          equals('evil_script.sh'),
        );

        // Excessive dots and leading symbols
        expect(
          FileDownloadHelper.sanitizeFileName('....//....//payload.jpg'),
          equals('payload.jpg'),
        );

        expect(
          FileDownloadHelper.sanitizeFileName('.hidden_malicious.exe'),
          equals('hidden_malicious.exe'),
        );

        // Empty or invalid traversal resulting in fallback
        expect(
          FileDownloadHelper.sanitizeFileName(
            '../../..',
            defaultName: 'safe.jpg',
          ),
          equals('safe.jpg'),
        );

        expect(
          FileDownloadHelper.sanitizeFileName(
            '..',
            defaultName: 'fallback.jpg',
          ),
          equals('fallback.jpg'),
        );

        // Safe filenames remain intact
        expect(
          FileDownloadHelper.sanitizeFileName('profile_avatar.png'),
          equals('profile_avatar.png'),
        );

        expect(
          FileDownloadHelper.sanitizeFileName('my document 2026.pdf'),
          equals('my document 2026.pdf'),
        );
      },
    );

    test(
      'extractFileName sanitizes path traversal from manipulated URLs (SEC-12)',
      () {
        expect(
          FileDownloadHelper.extractFileName(
            'https://example.com/download/..%2f..%2fexploit.pdf',
          ),
          equals('exploit.pdf'),
        );

        expect(
          FileDownloadHelper.extractFileName(
            'https://example.com/files/%2e%2e%2fconfig.json',
          ),
          equals('config.json'),
        );
      },
    );

    test('isTrustedHost validates trusted vs untrusted domains (SEC-15)', () {
      expect(
        FileDownloadHelper.isTrustedHost(
          'https://app.kiranapeople.com/storage/photos/test.jpg',
        ),
        isTrue,
      );
      expect(
        ApiConfig.isTrustedHost(
          'https://attacker.onrender.com/storage/photos/test.jpg',
          null,
          false,
        ),
        isFalse,
      );
      expect(
        ApiConfig.isTrustedHost(
          'https://app.kiranapeople.com/storage/photos/test.jpg',
          null,
          false,
        ),
        isTrue,
      );
      expect(
        FileDownloadHelper.isTrustedHost('/storage/photos/test.jpg'),
        isTrue,
      );
      expect(
        FileDownloadHelper.isTrustedHost(
          'http://localhost:8000/api/v1/file.pdf',
        ),
        isTrue,
      );
      expect(
        FileDownloadHelper.isTrustedHost('http://10.0.2.2:8000/file.png'),
        isTrue,
      );
      expect(
        FileDownloadHelper.isTrustedHost(
          'https://terriblenight.onrender.com/api/v1/attendance/today',
        ),
        isTrue,
      );
      expect(
        ApiConfig.isTrustedHost(
          'https://terriblenight.onrender.com/api/v1/attendance/today',
          null,
          false,
        ),
        isFalse,
      );
      expect(
        FileDownloadHelper.isTrustedHost(
          'https://attacker.onrender.com/api/v1/attendance/today',
        ),
        isFalse,
      );
      expect(
        ApiConfig.isTrustedHost(
          'https://staging.internal.com/api/v1/test',
          'https://staging.internal.com/api/v1',
        ),
        isTrue,
      );
      expect(
        FileDownloadHelper.isTrustedHost(
          'https://staging.internal.com/api/v1/test',
          'https://staging.internal.com/api/v1',
        ),
        isTrue,
      );
      expect(
        FileDownloadHelper.isTrustedHost(
          'https://evil-third-party.com/payload.jpg',
        ),
        isFalse,
      );
      expect(
        FileDownloadHelper.isTrustedHost('https://attacker.org/exfiltrate'),
        isFalse,
      );
      expect(FileDownloadHelper.isTrustedHost(''), isFalse);
    });
  });

  group('PhotoPreviewDialog Download Button Tests', () {
    testWidgets(
      'PhotoPreviewDialog renders share, download, rotate, and close buttons',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PhotoPreviewDialog(
                imageUrl: 'https://example.com/photo.jpg',
                title: 'Foto Masuk Kerja',
                subtitle: '2 Nov 2026, 08:00',
              ),
            ),
          ),
        );

        // Verify title & subtitle
        expect(find.text('Foto Masuk Kerja'), findsOneWidget);
        expect(find.text('2 Nov 2026, 08:00'), findsOneWidget);

        // Verify buttons
        expect(find.byIcon(Icons.share_rounded), findsOneWidget);
        expect(find.byIcon(Icons.download_rounded), findsOneWidget);
        expect(find.byIcon(Icons.rotate_right_rounded), findsOneWidget);
        expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      },
    );

    testWidgets('Tapping rotate button rotates image', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PhotoPreviewDialog(
              imageUrl: 'https://example.com/photo.jpg',
              title: 'Foto Rotasi',
            ),
          ),
        ),
      );

      final rotateFinder = find.byIcon(Icons.rotate_right_rounded);
      expect(rotateFinder, findsOneWidget);

      await tester.tap(rotateFinder);
      await tester.pump();
    });
  });
}
