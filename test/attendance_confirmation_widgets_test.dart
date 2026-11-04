import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/data/models/attendance_event_model.dart';
import 'package:kirana_people/features/attendance/widgets/confirmation/confirmation_action_buttons.dart';
import 'package:kirana_people/features/attendance/widgets/confirmation/confirmation_app_bar.dart';
import 'package:kirana_people/features/attendance/widgets/confirmation/confirmation_dialogs.dart';

void main() {
  group('Attendance Confirmation Sub-Widgets Tests', () {
    testWidgets('ConfirmationAppBar renders action title and triggers callbacks', (tester) async {
      bool retakeCalled = false;
      bool cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfirmationAppBar(
              action: AttendanceEventType.startShift,
              onRetake: () => retakeCalled = true,
              onCancel: () => cancelCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Masuk Kerja'), findsOneWidget);
      expect(find.text('Foto'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);

      await tester.tap(find.text('Foto'));
      await tester.pump();
      expect(retakeCalled, isTrue);

      await tester.tap(find.text('Batal'));
      await tester.pump();
      expect(cancelCalled, isTrue);
    });

    testWidgets('ConfirmationActionButtons renders and triggers callbacks', (tester) async {
      bool retakeCalled = false;
      bool submitCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfirmationActionButtons(
              isSubmitting: false,
              onRetake: () => retakeCalled = true,
              onSubmit: () => submitCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Ambil Ulang'), findsOneWidget);
      expect(find.text('Simpan Presensi'), findsOneWidget);

      await tester.tap(find.text('Ambil Ulang'));
      await tester.pump();
      expect(retakeCalled, isTrue);

      await tester.tap(find.text('Simpan Presensi'));
      await tester.pump();
      expect(submitCalled, isTrue);
    });

    testWidgets('ConfirmationActionButtons shows progress spinner when isSubmitting is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfirmationActionButtons(
              isSubmitting: true,
              onRetake: () {},
              onSubmit: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Simpan Presensi'), findsNothing);
    });

    testWidgets('ConfirmationDialogs can render offline warning dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ConfirmationDialogs.showOfflineWarningDialog(context),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Perangkat Offline'), findsOneWidget);
      expect(find.text('Mengerti'), findsOneWidget);

      await tester.tap(find.text('Mengerti'));
      await tester.pumpAndSettle();

      expect(find.text('Perangkat Offline'), findsNothing);
    });
  });
}

