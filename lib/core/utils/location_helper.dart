import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final bool isMocked;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.isMocked,
  });
}

class LocationHelper {
  static Position? _cachedPosition;
  static DateTime? _cachedAt;
  static Future<Position>? _inFlight;

  /// Pre-warms GPS in the background (e.g., while user is framing their selfie)
  /// so that the confirmation screen has an instant location lock.
  static Future<Position?> warmupPosition() async {
    try {
      return await determinePosition();
    } catch (_) {
      return null;
    }
  }

  static Future<Position> determinePosition({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedPosition != null &&
        _cachedAt != null &&
        now.difference(_cachedAt!).inSeconds < 60) {
      return _validatePosition(_cachedPosition!);
    }

    if (!forceRefresh && _inFlight != null) {
      return _inFlight!;
    }

    final future = _acquirePosition(forceRefresh: forceRefresh);
    _inFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    }
  }

  static Future<Position> _acquirePosition({required bool forceRefresh}) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'Layanan lokasi (GPS) nonaktif. Silakan aktifkan GPS pada perangkat Anda.',
      );
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak oleh pengguna.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Izin lokasi ditolak permanen. Silakan aktifkan izin lokasi di Pengaturan Sistem.',
      );
    }

    Position? lastPos;
    try {
      lastPos = await Geolocator.getLastKnownPosition();
    } catch (_) {}

    // If OS already has a fresh fix (< 60s old, reasonable accuracy) and not forcing refresh, use it immediately
    final checkTime = DateTime.now();
    if (!forceRefresh &&
        lastPos != null &&
        !lastPos.isMocked &&
        lastPos.accuracy >= 0 &&
        lastPos.accuracy <= 65 &&
        checkTime.difference(lastPos.timestamp).inSeconds.abs() <= 60) {
      final validated = _validatePosition(lastPos);
      _cachedPosition = validated;
      _cachedAt = checkTime;
      return validated;
    }

    Position? position;
    try {
      // Bound high-accuracy satellite lock to 4 seconds so indoor users aren't stuck waiting 12s
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );
    } catch (_) {
      // Fallback 1: If live high-accuracy GPS times out indoors, try a fast medium-accuracy (Wi-Fi/Cell) fix
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 3),
          ),
        );
      } catch (_) {}

      // Fallback 2: Accept recent cached position (max 10 minutes old)
      if (position == null) {
        lastPos ??= await Geolocator.getLastKnownPosition();
        final fallbackNow = DateTime.now();
        if (lastPos != null &&
            fallbackNow.difference(lastPos.timestamp).inMinutes.abs() <= 10) {
          position = lastPos;
        } else {
          throw Exception(
            'Gagal mendapatkan lokasi GPS terkini. Pastikan GPS aktif dan sinyal memadai.',
          );
        }
      }
    }

    final validated = _validatePosition(position);
    _cachedPosition = validated;
    _cachedAt = DateTime.now();
    return validated;
  }

  static Position _validatePosition(Position position) {
    if (position.isMocked) {
      _cachedPosition = null;
      _cachedAt = null;
      throw Exception(
        'Terdeteksi lokasi palsu (Fake GPS). Harap nonaktifkan aplikasi Fake GPS untuk presensi.',
      );
    }

    if (position.accuracy < 0) {
      throw Exception(
        'Akurasi sinyal GPS tidak valid. Pastikan GPS aktif dan berada di area terbuka.',
      );
    }

    // Anti-replay / Clock skew protection: Reject fixes with timestamps far in the future
    final now = DateTime.now();
    if (position.timestamp.difference(now).inSeconds > 60) {
      throw Exception(
        'Waktu perangkat tidak sinkron. Harap aktifkan pengaturan waktu otomatis sistem.',
      );
    }

    return position;
  }
}
