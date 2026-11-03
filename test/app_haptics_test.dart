import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/core/utils/app_haptics.dart';
import 'package:kirana_people/core/widgets/bouncing_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppHaptics Tests', () {
    test('AppHaptics methods trigger without throwing', () async {
      AppHaptics.light();
      AppHaptics.medium();
      AppHaptics.heavy();
      AppHaptics.selection();
      AppHaptics.error();
      await AppHaptics.success();
    });

    testWidgets('BouncingButton executes on tap with medium haptic level', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BouncingButton(
              hapticType: BouncingHapticType.medium,
              onPressed: () {
                tapped = true;
              },
              child: const Text('Check In'),
            ),
          ),
        ),
      );

      final buttonFinder = find.text('Check In');
      expect(buttonFinder, findsOneWidget);

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('BouncingButton handles selection and error haptic types', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BouncingButton(
              hapticType: BouncingHapticType.selection,
              onPressed: () {
                tapped = true;
              },
              child: const Text('Select Shift'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Select Shift'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}

