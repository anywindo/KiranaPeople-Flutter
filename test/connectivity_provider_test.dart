import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_people/core/network/api_client.dart';
import 'package:kirana_people/core/widgets/offline_banner.dart';
import 'package:kirana_people/providers/connectivity_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Connectivity & Offline UI Tests', () {
    test('Offline status detection logic from ConnectivityResult list', () {
      bool isOffline(List<ConnectivityResult> results) {
        if (results.isEmpty) return true;
        return results.every((r) => r == ConnectivityResult.none);
      }

      expect(isOffline([]), isTrue);
      expect(isOffline([ConnectivityResult.none]), isTrue);
      expect(isOffline([ConnectivityResult.wifi]), isFalse);
      expect(isOffline([ConnectivityResult.mobile]), isFalse);
      expect(isOffline([ConnectivityResult.ethernet]), isFalse);
      expect(isOffline([ConnectivityResult.vpn, ConnectivityResult.none]), isFalse);
    });

    testWidgets('OfflineCardWarning does not render when device is online', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOfflineProvider.overrideWith(() => _MockConnectivityNotifier(false)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OfflineCardWarning(),
            ),
          ),
        ),
      );

      expect(find.text('Koneksi Internet Terputus'), findsNothing);
    });

    testWidgets('OfflineCardWarning renders alert when device is offline', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOfflineProvider.overrideWith(() => _MockConnectivityNotifier(true)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OfflineCardWarning(
                message: 'Perangkat Anda sedang offline.',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Koneksi Internet Terputus'), findsOneWidget);
      expect(find.text('Perangkat Anda sedang offline.'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });

    testWidgets('OfflineBanner renders when offline', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOfflineProvider.overrideWith(() => _MockConnectivityNotifier(true)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OfflineBanner(),
            ),
          ),
        ),
      );

      expect(find.text('Mode Offline (Tidak Ada Internet)'), findsOneWidget);
      expect(find.text('Periksa Wi-Fi atau kuota data seluler Anda.'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });

    test('ApiClient.onServerReachabilityChanged updates ConnectivityNotifier state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initially online (false)
      expect(container.read(isOfflineProvider), isFalse);

      // Trigger server unreachable (e.g. timeout or 502)
      ApiClient.onServerReachabilityChanged?.call(false);
      expect(container.read(isOfflineProvider), isTrue);

      // Trigger server reachable
      ApiClient.onServerReachabilityChanged?.call(true);
      expect(container.read(isOfflineProvider), isFalse);
    });

    test('checkConnection sets offline when backend health check fails', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(isOfflineProvider.notifier);
      notifier.setDependencies(apiClient: _MockHealthApiClient(isHealthy: false));

      await notifier.checkConnection(force: true);
      expect(container.read(isOfflineProvider), isTrue);
    });

    test('checkConnection sets online when backend health check succeeds', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(isOfflineProvider.notifier);
      // First force offline
      ApiClient.onServerReachabilityChanged?.call(false);
      expect(container.read(isOfflineProvider), isTrue);

      // Verify health check restores online mode
      notifier.setDependencies(apiClient: _MockHealthApiClient(isHealthy: true));
      await notifier.checkConnection(force: true);
      expect(container.read(isOfflineProvider), isFalse);
    });
  });
}

class _MockHealthApiClient extends ApiClient {
  final bool isHealthy;
  _MockHealthApiClient({required this.isHealthy});

  @override
  Future<bool> checkServerHealth({Duration timeout = const Duration(seconds: 4)}) async {
    return isHealthy;
  }
}

class _MockConnectivityNotifier extends ConnectivityNotifier {
  final bool initialOffline;
  _MockConnectivityNotifier(this.initialOffline);

  @override
  bool build() {
    return initialOffline;
  }
}

