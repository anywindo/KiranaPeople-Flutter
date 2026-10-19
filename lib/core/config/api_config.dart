import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String defaultBaseUrl = 'https://terriblenight.onrender.com/api/v1';
  static const String _keyCustomBaseUrl = 'custom_api_base_url';

  static final List<Map<String, String>> presets = [
    {
      'label': 'Render Cloud (Produksi)',
      'url': 'https://terriblenight.onrender.com/api/v1',
    },
    {
      'label': 'Android Emulator (10.0.2.2:8000)',
      'url': 'http://10.0.2.2:8000/api/v1',
    },
    {
      'label': 'iOS Simulator / Localhost (127.0.0.1:8000)',
      'url': 'http://127.0.0.1:8000/api/v1',
    },
    {
      'label': 'Laravel Herd (terriblenight.test)',
      'url': 'https://terriblenight.test/api/v1',
    },
  ];

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyCustomBaseUrl);
    if (saved == null || saved.trim().isEmpty) {
      return defaultBaseUrl;
    }
    return sanitizeUrl(saved);
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final cleaned = sanitizeUrl(url);
    await prefs.setString(_keyCustomBaseUrl, cleaned);
  }

  static Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCustomBaseUrl);
  }

  static String sanitizeUrl(String raw) {
    var str = raw.trim();
    if (str.isEmpty) {
      return defaultBaseUrl;
    }

    // Auto-correct common typos
    if (str.contains('arwdnoprtma.space')) {
      str = str.replaceAll('arwdnoprtma.space', 'arwndoprtma.space');
    }

    // Add http/https scheme if missing
    if (!str.startsWith('http://') && !str.startsWith('https://')) {
      if (str.startsWith('localhost') ||
          str.startsWith('127.0.0.1') ||
          str.startsWith('10.0.2.2') ||
          str.startsWith('192.168.') ||
          str.startsWith('10.') ||
          str.startsWith('172.')) {
        str = 'http://$str';
      } else {
        str = 'https://$str';
      }
    }

    // Remove trailing slashes
    while (str.endsWith('/')) {
      str = str.substring(0, str.length - 1);
    }

    // Fix duplicated /api/api/v1
    if (str.contains('/api/api/v1')) {
      str = str.replaceAll('/api/api/v1', '/api/v1');
    }

    // Append /api/v1 if path is empty
    try {
      final uri = Uri.parse(str);
      if (uri.path.isEmpty || uri.path == '/') {
        str = '$str/api/v1';
      }
    } catch (_) {}

    return str;
  }
}
