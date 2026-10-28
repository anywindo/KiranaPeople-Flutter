import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DeviceSecurityService {
  static final DeviceSecurityService _instance =
      DeviceSecurityService._internal();
  factory DeviceSecurityService() => _instance;
  DeviceSecurityService._internal();

  static const MethodChannel _channel =
      MethodChannel('com.kiranadesainindonesia.kiranapeople/security');

  bool? _cachedIsCompromised;

  /// Checks if the device has root binaries (Android) or is jailbroken (iOS).
  /// Caches the result after first check to minimize IPC overhead.
  Future<bool> isDeviceCompromised({bool forceRefresh = false}) async {
    if (_cachedIsCompromised != null && !forceRefresh) {
      return _cachedIsCompromised!;
    }

    try {
      final bool? isCompromised =
          await _channel.invokeMethod<bool>('isDeviceCompromised');
      _cachedIsCompromised = isCompromised ?? false;
      return _cachedIsCompromised!;
    } on MissingPluginException {
      // Occurs during unit tests or environments without native platform channel handler
      return false;
    } on PlatformException catch (e) {
      debugPrint(
        '[DeviceSecurityService] Platform error detecting root/jailbreak: $e',
      );
      return false;
    } catch (e) {
      debugPrint('[DeviceSecurityService] Unexpected error: $e');
      return false;
    }
  }

  /// Checks if Developer Mode is enabled (Android only).
  Future<bool> isDeveloperMode() async {
    try {
      final bool? isDev = await _channel.invokeMethod<bool>('isDeveloperMode');
      return isDev ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Resets cached security state (useful for unit testing).
  @visibleForTesting
  void resetCache() {
    _cachedIsCompromised = null;
  }
}
