import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_people/main.dart';

void main() {
  testWidgets('App initializes smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: KiranaPeopleApp(),
      ),
    );

    // Initial check shows session check or login screen
    expect(find.byType(KiranaPeopleApp), findsOneWidget);
  });
}
