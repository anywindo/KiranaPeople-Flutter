import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/data/models/attendance_event_model.dart';
import 'package:kirana_people/data/models/attendance_model.dart';
import 'package:kirana_people/data/models/shift_model.dart';
import 'package:kirana_people/features/attendance/utils/attendance_event_resolver.dart';
import 'package:kirana_people/features/attendance/widgets/attendance_error_dialog.dart';
import 'package:kirana_people/features/attendance/widgets/attendance_logout_dialog.dart';

void main() {
  group('AttendanceEventTimeline Tests', () {
    test('resolveTargetAction returns startShift when events are empty', () {
      final target = AttendanceEventTimeline.resolveTargetAction(
        data: null,
        activeSegment: 0,
      );
      expect(target, equals(AttendanceEventType.startShift));
    });

    test('resolveTargetAction respects nextAllowedAction if provided', () {
      final data = TodayAttendanceData(
        status: 'HADIR',
        nextAllowedAction: 'START_BREAK',
        events: [],
      );
      final target = AttendanceEventTimeline.resolveTargetAction(
        data: data,
        activeSegment: 0,
      );
      expect(target, equals(AttendanceEventType.startBreak));
    });

    test('resolveTargetAction determines break modes when activeSegment is 1', () {
      final dataBeforeBreak = TodayAttendanceData(
        status: 'HADIR',
        events: [
          AttendanceEvent(
            id: 1,
            eventType: AttendanceEventType.startShift,
            timestamp: '2026-11-04T08:00:00Z',
          ),
        ],
      );

      final target1 = AttendanceEventTimeline.resolveTargetAction(
        data: dataBeforeBreak,
        activeSegment: 1,
      );
      expect(target1, equals(AttendanceEventType.startBreak));

      final dataDuringBreak = TodayAttendanceData(
        status: 'HADIR',
        events: [
          AttendanceEvent(
            id: 1,
            eventType: AttendanceEventType.startShift,
            timestamp: '2026-11-04T08:00:00Z',
          ),
          AttendanceEvent(
            id: 2,
            eventType: AttendanceEventType.startBreak,
            timestamp: '2026-11-04T12:00:00Z',
          ),
        ],
      );

      final target2 = AttendanceEventTimeline.resolveTargetAction(
        data: dataDuringBreak,
        activeSegment: 1,
      );
      expect(target2, equals(AttendanceEventType.endBreak));
    });

    test('AttendanceEventTimeline.fromData correctly extracts times and flags', () {
      final shift = Shift(
        id: 1,
        name: 'Normal Shift',
        startTime: '08:00',
        endTime: '17:00',
        attendanceRuleEnabled: true,
        attendanceRuleMinutes: 15,
      );

      final data = TodayAttendanceData(
        status: 'HADIR',
        shift: shift,
        events: [
          AttendanceEvent(
            id: 1,
            eventType: AttendanceEventType.startShift,
            timestamp: '2026-11-04T08:05:00',
          ),
        ],
      );

      final timeline = AttendanceEventTimeline.fromData(
        data: data,
        selectedShift: shift,
      );

      expect(timeline.hasStartedShift, isTrue);
      expect(timeline.isCheckInLate, isTrue); // 08:05 >= cutoff 07:45 -> late
      expect(timeline.hasEndedShift, isFalse);
      expect(timeline.hasStartedBreak, isFalse);
      expect(timeline.isOnBreak, isFalse);
      expect(timeline.checkInTime, equals('08:05'));
    });
  });

  group('Attendance Dialogs Tests', () {
    testWidgets('AttendanceLogoutDialog renders and triggers callbacks', (tester) async {
      bool logoutConfirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => AttendanceLogoutDialog.show(
                  ctx,
                  onConfirmLogout: () => logoutConfirmed = true,
                ),
                child: const Text('Open Logout'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Logout'));
      await tester.pumpAndSettle();

      expect(find.text('Keluar Akun'), findsOneWidget);
      expect(find.text('Apakah Anda yakin ingin keluar dari akun ini?'), findsOneWidget);

      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();

      expect(logoutConfirmed, isTrue);
    });

    testWidgets('AttendanceErrorDialog renders error message and dismisses', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => AttendanceErrorDialog.show(
                  ctx,
                  errorMessage: 'Lokasi Anda berada di luar radius kantor.',
                  onDismiss: () => dismissed = true,
                ),
                child: const Text('Open Error'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Error'));
      await tester.pumpAndSettle();

      expect(find.text('Presensi Belum Tersimpan'), findsOneWidget);
      expect(find.text('Lokasi Anda berada di luar radius kantor.'), findsOneWidget);

      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
      expect(find.text('Presensi Belum Tersimpan'), findsNothing);
    });
  });
}
