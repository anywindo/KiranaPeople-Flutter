import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'attendance_provider.dart';
import 'history_provider.dart';

class ConnectivityNotifier extends Notifier<bool> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final Connectivity _connectivity = Connectivity();

  @override
  bool build() {
    _init();
    ref.onDispose(() {
      _subscription?.cancel();
    });
    // Default to false (online) initially until checked
    return false;
  }

  Future<void> _init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      state = _checkIsOffline(results);
    } catch (e) {
      debugPrint('[ConnectivityProvider] Initial check error: $e');
      state = false;
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final wasOffline = state;
      final nowOffline = _checkIsOffline(results);

      if (state != nowOffline) {
        state = nowOffline;
        debugPrint(
          '[ConnectivityProvider] Network state changed: ${nowOffline ? "OFFLINE" : "ONLINE"}',
        );

        // When restoring connection, automatically re-sync attendance & history data
        if (wasOffline && !nowOffline) {
          _triggerReconnectionSync();
        }
      }
    });
  }

  bool _checkIsOffline(List<ConnectivityResult> results) {
    if (results.isEmpty) return true;
    return results.every((r) => r == ConnectivityResult.none);
  }

  Future<void> checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      state = _checkIsOffline(results);
    } catch (_) {}
  }

  void _triggerReconnectionSync() {
    try {
      ref.read(todayAttendanceProvider.notifier).refresh(isBackground: true);
      ref.read(historyProvider.notifier).refresh(isBackground: true);
    } catch (_) {}
  }
}

final isOfflineProvider = NotifierProvider<ConnectivityNotifier, bool>(
  ConnectivityNotifier.new,
);

