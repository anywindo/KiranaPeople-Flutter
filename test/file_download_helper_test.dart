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
        FileDownloadHelper.extractFileName('https://kp.krtekstile.com/storage/photos/selfie_123.jpg'),
        equals('selfie_123.jpg'),
      );

      expect(
        FileDownloadHelper.extractFileName('https://kp.krtekstile.com/media/doc_scan.png?token=xyz#preview'),
        equals('doc_scan.png'),
      );

      expect(
        FileDownloadHelper.extractFileName('https://kp.krtekstile.com/media/user%20photo.webp'),
        equals('user photo.webp'),
      );

      expect(
        FileDownloadHelper.extractFileName('/storage/emulated/0/Pictures/captured.jpeg'),
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
  });

  group('PhotoPreviewDialog Download Button Tests', () {
    testWidgets('PhotoPreviewDialog renders share, download, rotate, and close buttons', (tester) async {
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
    });

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

