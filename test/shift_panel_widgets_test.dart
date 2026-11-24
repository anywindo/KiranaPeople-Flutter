import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/core/theme/app_theme.dart';
import 'package:kirana_people/data/models/attendance_event_model.dart';
import 'package:kirana_people/data/models/attendance_model.dart';
import 'package:kirana_people/data/models/shift_model.dart';
import 'package:kirana_people/features/attendance/widgets/shift/shift_break_panel.dart';
import 'package:kirana_people/features/attendance/widgets/shift/shift_card_header.dart';
import 'package:kirana_people/features/attendance/widgets/shift/shift_work_panel.dart';

void main() {
  group('Shift Panel Sub-Widgets Tests', () {
    testWidgets('ShiftCardHeader renders date and submitting indicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                ShiftCardHeader(
                  currentDate: DateTime(2026, 10, 19),
                  isSubmitting: false,
                ),
                ShiftCardHeader(
                  currentDate: DateTime(2026, 10, 19),
                  isSubmitting: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Hari Ini (Sen, 19 Okt 2026)'), findsNWidgets(2));
      expect(find.text('Menyinkronkan...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'ShiftWorkPanel renders shift details and triggers onPickShift',
      (tester) async {
        bool pickTapped = false;
        final shift = Shift(
          id: 1,
          name: 'Shift Pagi',
          startTime: '08:00:00',
          endTime: '17:00:00',
          breakStartTime: '12:00:00',
          breakEndTime: '13:00:00',
        );

        final todayData = TodayAttendanceData(availableShifts: [shift]);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: ShiftWorkPanel(
                selectedShift: shift,
                todayData: todayData,
                hasStartedShift: false,
                isCheckInLate: false,
                hasEndedShift: false,
                checkInTime: null,
                checkOutTime: null,
                startShiftEvent: null,
                endShiftEvent: null,
                onPickShift: () => pickTapped = true,
              ),
            ),
          ),
        );

        expect(find.text('Shift Pagi (08:00 - 17:00)'), findsOneWidget);
        expect(find.text('Pilih'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText().contains('Jam Masuk'),
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText().contains('Jam Pulang'),
          ),
          findsOneWidget,
        );
        expect(find.text('--:--'), findsNWidgets(2));

        await tester.tap(find.text('Pilih'));
        await tester.pump();
        expect(pickTapped, isTrue);
      },
    );

    testWidgets(
      'ShiftBreakPanel renders guidance banner when work shift not started',
      (tester) async {
        bool switchToWorkTapped = false;
        final shift = Shift(
          id: 1,
          name: 'Shift Pagi',
          startTime: '08:00:00',
          endTime: '17:00:00',
          breakStartTime: '12:00:00',
          breakEndTime: '13:00:00',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: ShiftBreakPanel(
                selectedShift: shift,
                hasStartedShift: false,
                hasStartedBreak: false,
                hasEndedBreak: false,
                hasEndedShift: false,
                startBreakTime: null,
                endBreakTime: null,
                startBreakEvent: null,
                endBreakEvent: null,
                onSwitchToWork: () => switchToWorkTapped = true,
              ),
            ),
          ),
        );

        expect(
          find.textContaining('Jam Istirahat: [12:00 - 13:00]'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Presensi Masuk Kerja belum dilakukan'),
          findsOneWidget,
        );
        expect(find.text('Masuk'), findsOneWidget);

        await tester.tap(find.text('Masuk'));
        await tester.pump();
        expect(switchToWorkTapped, isTrue);
      },
    );

    testWidgets(
      'ShiftBreakPanel renders completed break guidance when break ended',
      (tester) async {
        bool switchToWorkTapped = false;
        final shift = Shift(
          id: 1,
          name: 'Shift Pagi',
          startTime: '08:00:00',
          endTime: '17:00:00',
          breakStartTime: '12:00:00',
          breakEndTime: '13:00:00',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: ShiftBreakPanel(
                selectedShift: shift,
                hasStartedShift: true,
                hasStartedBreak: true,
                hasEndedBreak: true,
                hasEndedShift: false,
                startBreakTime: '12:05',
                endBreakTime: '12:55',
                startBreakEvent: null,
                endBreakEvent: null,
                onSwitchToWork: () => switchToWorkTapped = true,
              ),
            ),
          ),
        );

        expect(find.text('Selesai'), findsOneWidget);
        expect(
          find.textContaining('Istirahat selesai. Lakukan Pulang Kerja'),
          findsOneWidget,
        );
        expect(find.text('Ke Kerja'), findsOneWidget);

        await tester.tap(find.text('Ke Kerja'));
        await tester.pump();
        expect(switchToWorkTapped, isTrue);
      },
    );

    testWidgets(
      'ShiftWorkPanel renders RED checkmark icon for Jam Pulang when check out is early',
      (tester) async {
        final shift = Shift(
          id: 1,
          name: 'Shift Kantor',
          startTime: '08:00:00',
          endTime: '16:00:00',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: ShiftWorkPanel(
                selectedShift: shift,
                todayData: null,
                hasStartedShift: true,
                isCheckInLate: false,
                isCheckOutEarly: true,
                hasEndedShift: true,
                checkInTime: '07:40',
                checkOutTime: '13:39',
                startShiftEvent: AttendanceEvent(
                  eventType: AttendanceEventType.startShift,
                  timestamp: '2026-11-16 07:40:00',
                ),
                endShiftEvent: AttendanceEvent(
                  eventType: AttendanceEventType.endShift,
                  timestamp: '2026-11-16 13:39:00',
                ),
                onPickShift: () {},
              ),
            ),
          ),
        );

        // Verify check in and check out times are rendered
        expect(find.text('07:40'), findsOneWidget);
        expect(find.text('13:39'), findsOneWidget);

        // Check the check icons
        final checkIcons = tester
            .widgetList<Icon>(find.byIcon(Icons.check_circle_rounded))
            .toList();
        expect(checkIcons.length, equals(2));

        // First check icon (Jam Masuk, on-time): green
        expect(checkIcons[0].color, equals(const Color(0xFF10B981)));

        // Second check icon (Jam Pulang, early at 13:39 < 16:00): red (0xFFEF4444)
        expect(checkIcons[1].color, equals(const Color(0xFFEF4444)));
      },
    );

    testWidgets(
      'ShiftWorkPanel renders GREEN checkmark icon for Jam Pulang when check out is on-time',
      (tester) async {
        final shift = Shift(
          id: 1,
          name: 'Shift Kantor',
          startTime: '08:00:00',
          endTime: '16:00:00',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: ShiftWorkPanel(
                selectedShift: shift,
                todayData: null,
                hasStartedShift: true,
                isCheckInLate: false,
                isCheckOutEarly: false,
                hasEndedShift: true,
                checkInTime: '07:40',
                checkOutTime: '16:05',
                startShiftEvent: AttendanceEvent(
                  eventType: AttendanceEventType.startShift,
                  timestamp: '2026-11-16 07:40:00',
                ),
                endShiftEvent: AttendanceEvent(
                  eventType: AttendanceEventType.endShift,
                  timestamp: '2026-11-16 16:05:00',
                ),
                onPickShift: () {},
              ),
            ),
          ),
        );

        final checkIcons = tester
            .widgetList<Icon>(find.byIcon(Icons.check_circle_rounded))
            .toList();
        expect(checkIcons.length, equals(2));

        // Both are green
        expect(checkIcons[0].color, equals(const Color(0xFF10B981)));
        expect(checkIcons[1].color, equals(const Color(0xFF10B981)));
      },
    );
  });
}
