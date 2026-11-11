import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kirana_people/core/config/api_config.dart';
import 'package:kirana_people/features/auth/login_screen.dart';
import 'package:kirana_people/features/auth/widgets/dev_api_endpoint_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiConfig.resetForTesting();
  });

  tearDown(() {
    ApiConfig.resetForTesting();
  });

  group('ApiConfig Dev Endpoint Tests', () {
    test('Default base URL and host origin are correct', () async {
      expect(await ApiConfig.getBaseUrl(), equals(ApiConfig.defaultBaseUrl));
      expect(ApiConfig.getHostOrigin(), equals(ApiConfig.cachedHostOrigin));
    });

    test('Setting custom base URL updates getBaseUrl and getHostOrigin', () async {
      await ApiConfig.setBaseUrl('http://10.0.2.2:8000/api/v1');
      expect(await ApiConfig.getBaseUrl(), equals('http://10.0.2.2:8000/api/v1'));
      expect(ApiConfig.getHostOrigin(), equals('http://10.0.2.2:8000'));

      // Test with custom domain
      await ApiConfig.setBaseUrl('https://staging-api.kirana.com/api/v1');
      expect(await ApiConfig.getBaseUrl(), equals('https://staging-api.kirana.com/api/v1'));
      expect(ApiConfig.getHostOrigin(), equals('https://staging-api.kirana.com'));
    });

    test('Resetting base URL restores default', () async {
      await ApiConfig.setBaseUrl('http://192.168.1.50:8000/api/v1');
      expect(await ApiConfig.getBaseUrl(), equals('http://192.168.1.50:8000/api/v1'));

      await ApiConfig.resetBaseUrl();
      expect(await ApiConfig.getBaseUrl(), equals(ApiConfig.defaultBaseUrl));
      expect(ApiConfig.getHostOrigin(), equals(ApiConfig.cachedHostOrigin));
    });
  });

  group('DevApiEndpointCard Widget Tests', () {
    testWidgets('renders DevApiEndpointCard header with default status', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DevApiEndpointCard(forceVisible: true),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dev: API Endpoint'), findsOneWidget);
      expect(find.text('DEFAULT'), findsOneWidget);
      expect(find.text(ApiConfig.defaultBaseUrl), findsOneWidget);
    });

    testWidgets('expands card and allows entering and saving custom endpoint', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DevApiEndpointCard(forceVisible: true),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap header to expand
      await tester.tap(find.text('Dev: API Endpoint'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Simpan'), findsOneWidget);
      expect(find.text('Reset Default'), findsOneWidget);

      // Tap preset chip for Android emulator
      await tester.tap(find.text('Android Emul (10.0.2.2:8000)'));
      await tester.pumpAndSettle();

      // Tap Simpan
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(await ApiConfig.getBaseUrl(), equals('http://10.0.2.2:8000/api/v1'));
      expect(find.text('CUSTOM'), findsOneWidget);
      expect(find.textContaining('Endpoint API disimpan: http://10.0.2.2:8000/api/v1'), findsOneWidget);
    });

    testWidgets('Reset Default button restores default URL', (tester) async {
      await ApiConfig.setBaseUrl('http://custom-dev:9000/api/v1');

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DevApiEndpointCard(forceVisible: true),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expand card
      await tester.tap(find.text('Dev: API Endpoint'));
      await tester.pumpAndSettle();

      expect(find.text('CUSTOM'), findsOneWidget);

      // Tap Reset Default
      await tester.tap(find.text('Reset Default'));
      await tester.pumpAndSettle();

      expect(await ApiConfig.getBaseUrl(), equals(ApiConfig.defaultBaseUrl));
      expect(find.text('DEFAULT'), findsOneWidget);
      expect(find.text('Endpoint API dikembalikan ke default.'), findsOneWidget);
    });

    testWidgets('LoginScreen hides DevApiEndpointCard by default and reveals it after 7 taps on Version footer', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // DevApiEndpointCard is hidden initially
      expect(find.text('Dev: API Endpoint'), findsNothing);

      final versionFinder = find.byKey(const Key('login_version_footer'));
      expect(versionFinder, findsOneWidget);
      await tester.ensureVisible(versionFinder);
      await tester.pumpAndSettle();

      // Tap 6 times - should still be hidden
      for (int i = 0; i < 6; i++) {
        await tester.tap(versionFinder);
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Dev: API Endpoint'), findsNothing);

      // 7th tap - unlocks and reveals card
      await tester.tap(versionFinder);
      await tester.pumpAndSettle();

      expect(find.text('Dev: API Endpoint'), findsOneWidget);

      // Tap 7 more times - toggles off and hides card
      for (int i = 0; i < 7; i++) {
        await tester.tap(versionFinder);
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();

      expect(find.text('Dev: API Endpoint'), findsNothing);
    });
  });
}
