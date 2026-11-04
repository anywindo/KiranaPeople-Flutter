import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/data/models/attendance_event_model.dart';
import 'package:kirana_people/features/attendance/attendance_submission_dialog.dart';
import 'package:kirana_people/features/attendance/widgets/submission/submission_error_banner.dart';
import 'package:kirana_people/features/attendance/widgets/submission/submission_notes_field.dart';
import 'package:kirana_people/features/attendance/widgets/submission/submission_selfie_preview.dart';

void main() {
  group('Attendance Submission Subwidgets & Dialog Tests', () {
    testWidgets('SubmissionErrorBanner renders error message correctly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SubmissionErrorBanner(
              errorMessage: 'Lokasi tidak akurat, harap coba lagi.',
            ),
          ),
        ),
      );

      expect(
        find.text('Lokasi tidak akurat, harap coba lagi.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('SubmissionNotesField takes user text and updates controller',
        (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubmissionNotesField(controller: controller),
          ),
        ),
      );

      expect(find.text('Catatan (Opsional)'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField),
        'Kerja lembur shift malam',
      );
      expect(controller.text, equals('Kerja lembur shift malam'));
    });

    testWidgets(
        'SubmissionSelfiePreview renders placeholder when selfie is null',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubmissionSelfiePreview(
              selfieImage: null,
              onTap: () => tapped = true,
              isSubmitting: false,
            ),
          ),
        ),
      );

      expect(find.text('Ketuk untuk Ambil Foto Selfie'), findsOneWidget);
      expect(find.text('Wajib verifikasi wajah'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);

      await tester.tap(find.text('Ketuk untuk Ambil Foto Selfie'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('SubmissionSelfiePreview blocks tap when isSubmitting is true',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubmissionSelfiePreview(
              selfieImage: null,
              onTap: () => tapped = true,
              isSubmitting: true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ketuk untuk Ambil Foto Selfie'));
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets('AttendanceSubmissionDialog renders title and action buttons',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AttendanceSubmissionDialog(
                eventType: AttendanceEventType.startShift,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Konfirmasi Masuk Kerja'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Kirim Presensi'), findsOneWidget);
      expect(find.text('Ketuk untuk Ambil Foto Selfie'), findsOneWidget);
    });
  });
}

