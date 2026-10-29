import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/core/widgets/continuous_marquee_text.dart';

void main() {
  group('ContinuousMarqueeText Tests', () {
    testWidgets('renders normally without animation when text fits within maxWidth', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: ContinuousMarqueeText(
                text: 'Short',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Only one single Text widget is in the tree because it does not overflow
      expect(find.text('Short'), findsOneWidget);
    });

    testWidgets('activates continuous scrolling marquee when text overflows maxWidth', (tester) async {
      const longText = 'Kantor Utama (Tersono, Batang, Jawa Tengah, Indonesia)';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100, // strictly constrained to cause overflow
              child: ContinuousMarqueeText(
                text: longText,
                style: TextStyle(fontSize: 14),
                velocity: 50.0,
                blankSpace: 20.0,
              ),
            ),
          ),
        ),
      );

      // Trigger post frame callback
      await tester.pump();

      // In marquee mode, two copies of the text exist for seamless looping
      expect(find.text(longText), findsNWidgets(2));

      // Advance animation partially
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(longText), findsNWidgets(2));

      // Advance animation further
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text(longText), findsNWidgets(2));
    });
  });
}

