import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/core/theme/app_theme.dart';
import 'package:kirana_people/data/models/shift_model.dart';
import 'package:kirana_people/features/attendance/widgets/attendance_action_button.dart';
import 'package:kirana_people/features/attendance/widgets/attendance_mode_switcher.dart';
import 'package:kirana_people/features/attendance/widgets/shift_info_card.dart';

void main() {
  group('Attendance Mode Transition Tests', () {
    testWidgets('AttendanceModeSwitcher toggles between Kerja and Istirahat smoothly', (tester) async {
      int activeSegment = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AttendanceModeSwitcher(
                  activeSegment: activeSegment,
                  onSegmentChanged: (newSegment) {
                    setState(() {
                      activeSegment = newSegment;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Kerja'), findsOneWidget);
      expect(find.text('Istirahat'), findsOneWidget);

      // Tap Istirahat tab
      await tester.tap(find.text('Istirahat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 150));

      expect(activeSegment, equals(1));

      // Tap Kerja tab
      await tester.tap(find.text('Kerja'));
      await tester.pumpAndSettle();

      expect(activeSegment, equals(0));
    });

    testWidgets('AttendanceModeSwitcher can be dragged smoothly between Kerja and Istirahat', (tester) async {
      int activeSegment = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SizedBox(
                  width: 320,
                  child: AttendanceModeSwitcher(
                    activeSegment: activeSegment,
                    onSegmentChanged: (newSegment) {
                      setState(() {
                        activeSegment = newSegment;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Initial state is Kerja (0)
      expect(activeSegment, equals(0));

      // Drag right from Kerja to Istirahat
      await tester.drag(find.text('Kerja'), const Offset(150, 0));
      await tester.pumpAndSettle();

      expect(activeSegment, equals(1));

      // Drag left from Istirahat to Kerja
      await tester.drag(find.text('Istirahat'), const Offset(-150, 0));
      await tester.pumpAndSettle();

      expect(activeSegment, equals(0));
    });

    testWidgets('ShiftInfoCard transitions smoothly with AnimatedSize and AnimatedSwitcher', (tester) async {
      final shift = Shift(
        id: 1,
        name: 'Normal',
        startTime: '08:00:00',
        endTime: '17:00:00',
        breakStartTime: '12:00:00',
        breakEndTime: '13:00:00',
      );

      int activeSegment = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      AttendanceModeSwitcher(
                        activeSegment: activeSegment,
                        onSegmentChanged: (s) => setState(() => activeSegment = s),
                      ),
                      ShiftInfoCard(
                        activeSegment: activeSegment,
                        selectedShift: shift,
                        todayData: null,
                        isSubmitting: false,
                        hasStartedShift: true,
                        isCheckInLate: false,
                        hasEndedShift: false,
                        hasStartedBreak: false,
                        hasEndedBreak: false,
                        checkInTime: '07:55',
                        checkOutTime: null,
                        startBreakTime: null,
                        endBreakTime: null,
                        startShiftEvent: null,
                        endShiftEvent: null,
                        startBreakEvent: null,
                        endBreakEvent: null,
                        onPickShift: () {},
                        onSwitchToWork: () {},
                        actionButton: AttendanceActionButton(
                          isLoading: false,
                          hasEndedShift: false,
                          hasStartedShift: true,
                          hasStartedBreak: false,
                          hasEndedBreak: false,
                          isOnBreak: false,
                          activeSegment: activeSegment,
                          selectedShift: shift,
                          onAction: () {},
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      // In Kerja mode (0)
      expect(find.textContaining('Normal (08:00 - 17:00)'), findsOneWidget);

      // Switch to Istirahat mode (1)
      await tester.tap(find.text('Istirahat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // In Istirahat mode (1)
      expect(find.textContaining('Jam Istirahat: [12:00 - 13:00]'), findsOneWidget);
    });

    testWidgets('AttendanceActionButton crossfades smoothly on segment change', (tester) async {
      int segment = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => setState(() => segment = segment == 0 ? 1 : 0),
                      child: const Text('Toggle Segment'),
                    ),
                    AttendanceActionButton(
                      isLoading: false,
                      hasEndedShift: false,
                      hasStartedShift: false,
                      hasStartedBreak: false,
                      hasEndedBreak: false,
                      isOnBreak: false,
                      activeSegment: segment,
                      selectedShift: null,
                      onAction: () {},
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // In segment 0: should show 'Masuk Kerja'
      expect(find.text('Masuk Kerja'), findsOneWidget);

      // Toggle to segment 1: should show 'Belum Masuk Kerja'
      await tester.tap(find.text('Toggle Segment'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(find.text('Belum Masuk Kerja'), findsOneWidget);
    });
  });
}
