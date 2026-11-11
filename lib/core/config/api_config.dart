import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String defaultBaseUrl = 'https://kp.krtekstile.com/api/v1';
  static const String cachedHostOrigin = 'https://kp.krtekstile.com';
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
