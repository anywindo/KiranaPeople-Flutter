import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String defaultBaseUrl = 'https://app.kiranapeople.com/api/v1';
  static const String cachedHostOrigin = 'https://app.kiranapeople.com';
  static const String prefKeyCustomBaseUrl = 'custom_dev_api_base_url';

  static String? _devBaseUrl;

  static String getHostOrigin([String? baseUrl]) {
    final target = baseUrl ?? (kDebugMode ? _devBaseUrl : null);
    if (target == null || target.isEmpty) {
      return cachedHostOrigin;
    }
    try {
      final uri = Uri.parse(target);
      final portPart = uri.hasPort && uri.port != 80 && uri.port != 443
          ? ':${uri.port}'
          : '';
      return '${uri.scheme}://${uri.host}$portPart';
    } catch (_) {
      return cachedHostOrigin;
    }
  }

  /// SECURITY (SEC-15): Validates whether a target URL/path belongs to the trusted application API host.
  /// Used by interceptors and download helpers to prevent leaking Bearer tokens to untrusted third-party hosts.
  static bool isTrustedHost(String urlOrPath) {
    final trimmed = urlOrPath.trim();
    if (trimmed.isEmpty) return false;
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return true; // Relative or local path resolves to trusted application backend
    }
    try {
      final uri = Uri.parse(trimmed);
      final host = uri.host.toLowerCase();
      final trustedHost = Uri.parse(cachedHostOrigin).host.toLowerCase();
      if (host == trustedHost) {
        return true;
      }
      if (kDebugMode) {
        if (host == 'localhost' ||
            host == '127.0.0.1' ||
            host == '10.0.2.2' ||
            host.endsWith('.test') ||
            host.startsWith('192.168.') ||
            host.startsWith('10.')) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<String> getBaseUrl() async {
    if (!kDebugMode) return defaultBaseUrl;
    if (_devBaseUrl != null && _devBaseUrl!.isNotEmpty) {
      return _devBaseUrl!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final custom = prefs.getString(prefKeyCustomBaseUrl);
      if (custom != null && custom.trim().isNotEmpty) {
        _devBaseUrl = custom.trim();
        return _devBaseUrl!;
      }
    } catch (_) {}
    return defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String? url) async {
    if (!kDebugMode) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (url == null || url.trim().isEmpty || url.trim() == defaultBaseUrl) {
        await prefs.remove(prefKeyCustomBaseUrl);
        _devBaseUrl = null;
      } else {
        final clean = url.trim();
        await prefs.setString(prefKeyCustomBaseUrl, clean);
        _devBaseUrl = clean;
      }
    } catch (_) {}
  }

  static Future<void> resetBaseUrl() async {
    await setBaseUrl(null);
  }

  @visibleForTesting
  static void setDevBaseUrlForTesting(String? url) {
    _devBaseUrl = url;
  }

  @visibleForTesting
  static void resetForTesting() {
    _devBaseUrl = null;
  }
}
