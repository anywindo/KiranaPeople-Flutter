import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/core/theme/app_theme.dart';
import 'package:kirana_people/core/widgets/haptic_refresh_indicator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HapticRefreshIndicator Widget Tests', () {
    testWidgets('renders child content properly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HapticRefreshIndicator(
              onRefresh: () async {},
              child: ListView(
                children: const [
                  Text('Item 1'),
                  Text('Item 2'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('triggers onRefresh callback when dragged down', (tester) async {
      bool refreshed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(primaryColor: AppColors.primary),
          home: Scaffold(
            body: HapticRefreshIndicator(
              triggerThreshold: 40.0,
              onRefresh: () async {
                refreshed = true;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: const [
                  SizedBox(height: 100, child: Text('List Item A')),
                  SizedBox(height: 100, child: Text('List Item B')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(refreshed, isFalse);

      // Perform fling gesture to drag down and release
      await tester.fling(find.text('List Item A'), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(refreshed, isTrue);

      await tester.pumpAndSettle();
    });

    testWidgets('handles overscroll with clamping physics without error', (tester) async {
      bool refreshed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HapticRefreshIndicator(
              onRefresh: () async {
                refreshed = true;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                children: const [
                  SizedBox(height: 80, child: Text('Clamping Item')),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.fling(find.text('Clamping Item'), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(refreshed, isTrue);

      await tester.pumpAndSettle();
    });
  });
}
