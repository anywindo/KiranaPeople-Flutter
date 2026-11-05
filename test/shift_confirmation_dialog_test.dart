import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/data/models/shift_model.dart';
import 'package:kirana_people/features/attendance/widgets/shift_confirmation_dialog.dart';

void main() {
  group('ShiftConfirmationDialog Tests', () {
    final shiftPagi = Shift(
      id: 1,
      name: 'Shift Pagi',
      startTime: '08:00:00',
      endTime: '16:00:00',
      breakStartTime: '12:00:00',
      breakEndTime: '13:00:00',
    );

    final shiftSiang = Shift(
      id: 2,
      name: 'Shift Siang',
      startTime: '13:00:00',
      endTime: '21:00:00',
      breakStartTime: '17:00:00',
      breakEndTime: '18:00:00',
    );

    testWidgets('renders dialog title, subtitle, shift info, and action buttons',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ShiftConfirmationDialog.show(
                    context,
                    shift: shiftPagi,
                    availableShifts: [shiftPagi],
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi Shift Kerja'), findsOneWidget);
      expect(
        find.text(
          'Pastikan shift yang dipilih sudah sesuai sebelum memulai presensi Masuk Kerja.',
        ),
        findsOneWidget,
      );
      expect(find.text('Shift Pagi'), findsOneWidget);
      expect(find.text('08:00 - 16:00 WIB'), findsOneWidget);
      expect(find.text('Istirahat: 12:00 - 13:00'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Lanjutkan'), findsOneWidget);

      // "Pilih" button is always present so user can change shift
      expect(find.text('Pilih'), findsOneWidget);
    });

    testWidgets('shows Pilih button and opens ShiftPickerSheet to change shift',
        (tester) async {
      Shift? changedShift;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ShiftConfirmationDialog.show(
                    context,
                    shift: shiftPagi,
                    availableShifts: [shiftPagi, shiftSiang],
                    onShiftChanged: (s) {
                      changedShift = s;
                    },
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih'), findsOneWidget);
      expect(find.text('Shift Pagi'), findsOneWidget);

      // Tap "Pilih" to change shift
      await tester.tap(find.text('Pilih'));
      await tester.pumpAndSettle();

      // Bottom sheet is now open showing shifts
      expect(find.text('Pilih Shift Kerja'), findsOneWidget);
      expect(find.text('Shift Siang'), findsOneWidget);

      // Select Shift Siang
      await tester.tap(find.text('Shift Siang'));
      await tester.pumpAndSettle();

      // Confirm in sheet
      await tester.tap(find.text('Pilih Shift Ini'));
      await tester.pumpAndSettle();

      // Confirmation dialog is now updated with Shift Siang!
      expect(find.text('Shift Siang'), findsOneWidget);
      expect(find.text('13:00 - 21:00 WIB'), findsOneWidget);
      expect(changedShift?.id, equals(2));
      expect(changedShift?.name, equals('Shift Siang'));
    });

    testWidgets('tapping Batal returns false', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await ShiftConfirmationDialog.show(
                    context,
                    shift: shiftPagi,
                    availableShifts: [shiftPagi],
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
      expect(find.byType(ShiftConfirmationDialog), findsNothing);
    });

    testWidgets('tapping Lanjutkan returns true', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await ShiftConfirmationDialog.show(
                    context,
                    shift: shiftPagi,
                    availableShifts: [shiftPagi],
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.byType(ShiftConfirmationDialog), findsNothing);
    });
  });
}
