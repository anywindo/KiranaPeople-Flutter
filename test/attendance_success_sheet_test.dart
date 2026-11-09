import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/data/models/attendance_event_model.dart';
import 'package:kirana_people/data/models/attendance_submission_result.dart';
import 'package:kirana_people/features/attendance/widgets/attendance_success_sheet.dart';

void main() {
  group('AttendanceSuccessSheet Tests', () {
    testWidgets('renders success sheet with startShift details and inside radius badge', (tester) async {
      final sampleResult = AttendanceSubmissionResult(
        action: AttendanceEventType.startShift,
        timestamp: DateTime(2026, 11, 9, 8, 2, 15),
        isWithinRadius: true,
        distance: 14.2,
        locationName: 'Kantor Pusat Batang',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AttendanceSuccessSheet(result: sampleResult),
          ),
        ),
      );

      // Verify title & reassuring subtitle
      expect(find.text('Presensi Berhasil Dicatat!'), findsOneWidget);
      expect(find.text('Kehadiran Anda telah terverifikasi secara akurat.'), findsOneWidget);

      // Verify action label
      expect(find.text('Masuk Kerja'), findsOneWidget);

      // Verify radius status
      expect(find.text('Dalam Radius'), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);

      // Verify time and location
      expect(find.text('08:02:15 WIB'), findsOneWidget);
      expect(find.text('Senin, 9 November 2026'), findsOneWidget);
      expect(find.text('Kantor Pusat Batang'), findsOneWidget);
      expect(find.text('14 m dari kantor'), findsOneWidget);

      // Verify "Selesai" button
      expect(find.text('Selesai'), findsOneWidget);
    });

    testWidgets('renders success sheet with endShift details and outside radius badge', (tester) async {
      final sampleResult = AttendanceSubmissionResult(
        action: AttendanceEventType.endShift,
        timestamp: DateTime(2026, 11, 9, 17, 30, 0),
        isWithinRadius: false,
        distance: 120.8,
        locationName: 'Gudang Logistik',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AttendanceSuccessSheet(result: sampleResult),
          ),
        ),
      );

      expect(find.text('Pulang Kerja'), findsOneWidget);
      expect(find.text('Luar Radius'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('17:30:00 WIB'), findsOneWidget);
      expect(find.text('121 m dari kantor'), findsOneWidget);
    });

    testWidgets('tapping Selesai dismisses the modal bottom sheet', (tester) async {
      final sampleResult = AttendanceSubmissionResult(
        action: AttendanceEventType.startBreak,
        timestamp: DateTime(2026, 11, 9, 12, 0, 0),
        isWithinRadius: true,
        distance: 5.0,
        locationName: 'Kantor',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => AttendanceSuccessSheet.show(context, result: sampleResult),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Presensi Berhasil Dicatat!'), findsOneWidget);
      expect(find.text('Mulai Istirahat'), findsOneWidget);

      // Tap Selesai
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      // Sheet should be popped
      expect(find.text('Presensi Berhasil Dicatat!'), findsNothing);
    });

    testWidgets('auto-dismisses after 4 seconds', (tester) async {
      final sampleResult = AttendanceSubmissionResult(
        action: AttendanceEventType.endBreak,
        timestamp: DateTime(2026, 11, 9, 13, 0, 0),
        isWithinRadius: true,
        distance: 10.0,
        locationName: 'Kantor',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => AttendanceSuccessSheet.show(context, result: sampleResult),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Presensi Berhasil Dicatat!'), findsOneWidget);

      // Advance time past the 4s auto-dismiss
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(find.text('Presensi Berhasil Dicatat!'), findsNothing);
    });
  });
}
