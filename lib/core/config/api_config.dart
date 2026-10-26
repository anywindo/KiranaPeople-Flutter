class ApiConfig {
  static const String defaultBaseUrl = 'https://kp.krtekstile.com/api/v1';
  static const String cachedHostOrigin = 'https://kp.krtekstile.com';

  static String getHostOrigin([String? baseUrl]) {
    if (baseUrl == null || baseUrl.isEmpty) {
      return cachedHostOrigin;
    }
    try {
      final uri = Uri.parse(baseUrl);
      final portPart = uri.hasPort && uri.port != 80 && uri.port != 443
          ? ':${uri.port}'
          : '';
      return '${uri.scheme}://${uri.host}$portPart';
    } catch (_) {
      return cachedHostOrigin;
    }
  }

  static Future<String> getBaseUrl() async {
    return defaultBaseUrl;
  }
}
