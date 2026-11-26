import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Emits diagnostic logs only in debug builds (`kDebugMode`).
/// Prevents leaking URLs, tokens, or internal errors to device logs in release builds (SEC-22).
void appLog(
  String message, {
  String name = 'KiranaPeople',
  Object? error,
}) {
  if (!kDebugMode) return;
  developer.log(message, name: name, error: error);
}
