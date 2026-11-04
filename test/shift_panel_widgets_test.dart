import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/core/theme/app_theme.dart';
import 'package:kirana_people/data/models/attendance_model.dart';
import 'package:kirana_people/data/models/shift_model.dart';
import 'package:kirana_people/features/attendance/widgets/shift/shift_break_panel.dart';
import 'package:kirana_people/features/attendance/widgets/shift/shift_card_header.dart';
import 'package:kirana_people/features/attendance/widgets/shift/shift_work_panel.dart';

void main() {
  group('Shift Panel Sub-Widgets Tests', () {
    testWidgets('ShiftCardHeader renders date and submitting indicator', (tester) async {
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

    testWidgets('ShiftWorkPanel renders shift details and triggers onPickShift', (tester) async {
      bool pickTapped = false;
      final shift = Shift(
        id: 1,
        name: 'Shift Pagi',
        startTime: '08:00:00',
        endTime: '17:00:00',
        breakStartTime: '12:00:00',
        breakEndTime: '13:00:00',
      );

      final todayData = TodayAttendanceData(
        availableShifts: [shift],
      );

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
      expect(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Jam Masuk')), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Jam Pulang')), findsOneWidget);
      expect(find.text('--:--'), findsNWidgets(2));

      await tester.tap(find.text('Pilih'));
      await tester.pump();
      expect(pickTapped, isTrue);
    });


    testWidgets('ShiftBreakPanel renders guidance banner when work shift not started', (tester) async {
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

      expect(find.textContaining('Jam Istirahat: [12:00 - 13:00]'), findsOneWidget);
      expect(find.textContaining('Presensi Masuk Kerja belum dilakukan'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);

      await tester.tap(find.text('Masuk'));
      await tester.pump();
      expect(switchToWorkTapped, isTrue);
    });

    testWidgets('ShiftBreakPanel renders completed break guidance when break ended', (tester) async {
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
      expect(find.textContaining('Istirahat selesai. Lakukan Pulang Kerja'), findsOneWidget);
      expect(find.text('Ke Kerja'), findsOneWidget);

      await tester.tap(find.text('Ke Kerja'));
      await tester.pump();
      expect(switchToWorkTapped, isTrue);
    });
  });
}
