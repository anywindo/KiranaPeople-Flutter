import 'package:flutter/services.dart';

/// Centralized utility for tactile haptic feedback across the Kirana People app.
class AppHaptics {
  /// Subtle light impact for secondary actions, toggle taps, chips, and previews
  static void light() {
    HapticFeedback.lightImpact();
  }

  /// Tactile medium impact for primary actions (camera shutter, check-in, dialog confirmation)
  static void medium() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact for definitive state transitions
  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  /// Distinct tick for list scrolling, segment selection, tabs, and radio/check pickers
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Celebratory double-pulse tactile feedback on successful attendance submission
  static Future<void> success() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    HapticFeedback.lightImpact();
  }

  /// Distinct alert pulse on validation error, out-of-radius warning, or submission failure
  static void error() {
    HapticFeedback.vibrate();
  }
}
