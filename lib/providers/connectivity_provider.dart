import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import 'attendance_provider.dart';
import 'history_provider.dart';

class ConnectivityNotifier extends Notifier<bool> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _offlinePollTimer;
  Connectivity _connectivity = Connectivity();
  ApiClient _apiClient = ApiClient();

  bool _isChecking = false;
  DateTime? _lastTransitionTime;

  @visibleForTesting
  void setDependencies({Connectivity? connectivity, ApiClient? apiClient}) {
    if (connectivity != null) _connectivity = connectivity;
    if (apiClient != null) _apiClient = apiClient;
  }

  @override
  bool build() {
    _init();
    ref.onDispose(() {
      _subscription?.cancel();
      _offlinePollTimer?.cancel();
      ApiClient.onServerReachabilityChanged = null;
    });
    // Default to false (online) initially
    return false;
  }

  Future<void> _init() async {
    // Listen to real-time reachability feedback from all ongoing API calls
    ApiClient.onServerReachabilityChanged = (isReachable) {
      if (!ref.mounted) return;
      if (isReachable) {
        _setOnline(force: true);
      } else {
        _setOffline(force: true);
      }
    };

    // Run initial health check verification
    try {
      await checkConnection();
    } catch (_) {}

    // Listen to device network interface changes (Wi-Fi on/off, Airplane mode, Mobile data)
    try {
      _subscription = _connectivity.onConnectivityChanged.listen((
        results,
      ) async {
        if (!ref.mounted) return;
        final hasNoNetwork =
            results.isEmpty ||
            results.every((r) => r == ConnectivityResult.none);

        if (hasNoNetwork) {
          // Definitely no network available on device
          _setOffline();
        } else {
          // Network interface available, verify actual API health
          await checkConnection();
        }
      });
    } catch (e) {
      debugPrint(
        '[ConnectivityProvider] onConnectivityChanged subscription skipped: $e',
      );
    }
  }

  /// Verifies connectivity by performing an actual health check against the backend API.
  Future<void> checkConnection({bool force = false}) async {
    if (!ref.mounted) return;
    if (_isChecking && !force) return;
    _isChecking = true;

    try {
      final results = await _connectivity.checkConnectivity();
      final hasNoNetwork =
          results.isEmpty || results.every((r) => r == ConnectivityResult.none);

      if (hasNoNetwork) {
        _setOffline();
        return;
      }
    } catch (e) {
      debugPrint('[ConnectivityProvider] Physical network check skipped: $e');
    }

    try {
      // Check real reachability to backend API
      final isHealthy = await _apiClient.checkServerHealth();
      if (!ref.mounted) return;
      if (isHealthy) {
        _setOnline(force: force);
      } else {
        _setOffline(force: force);
      }
    } catch (e) {
      debugPrint('[ConnectivityProvider] checkConnection error: $e');
      if (ref.mounted) {
        _setOffline(force: force);
      }
    } finally {
      _isChecking = false;
    }
  }

  void _setOffline({bool force = false}) {
    if (!ref.mounted || state == true) {
      return; // Already offline, no-op (no flicker)
    }

    final now = DateTime.now();
    if (!force &&
        _lastTransitionTime != null &&
        now.difference(_lastTransitionTime!).inMilliseconds < 400) {
      return; // Anti-flicker debounce
    }
    _lastTransitionTime = now;

    state = true;
    debugPrint(
      '[ConnectivityProvider] Switched to OFFLINE mode (API unreachable)',
    );

    // Start background polling while offline to automatically recover when API is back
    _startOfflinePolling();
  }

  void _setOnline({bool force = false}) {
    if (!ref.mounted || state == false) {
      return; // Already online, no-op (no flicker)
    }

    final now = DateTime.now();
    if (!force &&
        _lastTransitionTime != null &&
        now.difference(_lastTransitionTime!).inMilliseconds < 400) {
      return; // Anti-flicker debounce
    }
    _lastTransitionTime = now;

    state = false;
    debugPrint(
      '[ConnectivityProvider] Switched to ONLINE mode (API reachable)',
    );

    // Stop polling once online to save battery and network
    _stopOfflinePolling();

    // Trigger auto re-sync of attendance & history data
    _triggerReconnectionSync();
  }

  void _startOfflinePolling() {
    _offlinePollTimer?.cancel();
    // Poll every 12 seconds while in offline mode to automatically detect API recovery
    _offlinePollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!ref.mounted) {
        _stopOfflinePolling();
        return;
      }
      if (state == true) {
        checkConnection();
      } else {
        _stopOfflinePolling();
      }
    });
  }

  void _stopOfflinePolling() {
    _offlinePollTimer?.cancel();
    _offlinePollTimer = null;
  }

  void _triggerReconnectionSync() {
    try {
      if (!ref.mounted) return;
      ref.read(todayAttendanceProvider.notifier).refresh(isBackground: true);
      ref.read(historyProvider.notifier).refresh(isBackground: true);
    } catch (_) {}
  }
}

final isOfflineProvider = NotifierProvider<ConnectivityNotifier, bool>(
  ConnectivityNotifier.new,
);
