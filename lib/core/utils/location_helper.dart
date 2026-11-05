import 'package:flutter/foundation.dart';
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

  /// Visible for testing to clear cached position state
  @visibleForTesting
  static void resetCache() {
    _cachedPosition = null;
    _cachedAt = null;
    _inFlight = null;
  }

  /// Visible for testing to seed cached position state
  @visibleForTesting
  static void seedCache(Position position, {DateTime? cachedAt}) {
    _cachedPosition = position;
    _cachedAt = cachedAt ?? DateTime.now();
  }

  /// Pre-warms GPS in the background (e.g., while user is framing their selfie)
  /// so that the confirmation screen has an instant location lock.
  static Future<Position?> warmupPosition() async {
    try {
      return await determinePosition();
    } catch (_) {
      return null;
    }
  }

  /// Determines current position with adaptive accuracy and battery optimization:
  /// - Reuses cache (< 60s old) to prevent redundant power draw
  /// - De-duplicates in-flight requests
  /// - Uses Android/iOS platform-tuned settings with indoor Wi-Fi/Cell fallback
  static Future<Position> determinePosition({
    bool forceRefresh = false,
    LocationAccuracy desiredAccuracy = LocationAccuracy.high,
  }) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedPosition != null &&
        _cachedAt != null &&
        now.difference(_cachedAt!).inSeconds < 60) {
      return validatePosition(_cachedPosition!);
    }

    if (!forceRefresh && _inFlight != null) {
      return _inFlight!;
    }

    final future = _acquirePosition(
      forceRefresh: forceRefresh,
      desiredAccuracy: desiredAccuracy,
    );
    _inFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    }
  }

  static Future<Position> _acquirePosition({
    required bool forceRefresh,
    required LocationAccuracy desiredAccuracy,
  }) async {
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

    // If OS already has a fresh fix (< 60s old, reasonable accuracy <= 65m) and not forcing refresh,
    // use it immediately to save battery and avoid running GPS chip unnecessarily.
    final checkTime = DateTime.now();
    if (!forceRefresh &&
        lastPos != null &&
        !lastPos.isMocked &&
        lastPos.accuracy >= 0 &&
        lastPos.accuracy <= 65 &&
        checkTime.difference(lastPos.timestamp).inSeconds.abs() <= 60) {
      final validated = validatePosition(lastPos);
      _cachedPosition = validated;
      _cachedAt = checkTime;
      return validated;
    }

    Position? position;
    try {
      // Platform-tailored settings: AndroidSettings with distanceFilter & interval
      final LocationSettings settings;
      if (defaultTargetPlatform == TargetPlatform.android) {
        settings = AndroidSettings(
          accuracy: desiredAccuracy,
          distanceFilter: 5,
          intervalDuration: const Duration(seconds: 3),
          timeLimit: const Duration(seconds: 5),
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        settings = AppleSettings(
          accuracy: desiredAccuracy,
          distanceFilter: 5,
          timeLimit: const Duration(seconds: 5),
          pauseLocationUpdatesAutomatically: true,
        );
      } else {
        settings = LocationSettings(
          accuracy: desiredAccuracy,
          timeLimit: const Duration(seconds: 5),
        );
      }

      position = await Geolocator.getCurrentPosition(
        locationSettings: settings,
      );
    } catch (_) {
      // Fallback 1: If live high-accuracy GPS times out indoors (e.g. basement, thick concrete),
      // quickly try medium-accuracy (Wi-Fi / Cell tower assisted) within 3s
      try {
        final LocationSettings fallbackSettings;
        if (defaultTargetPlatform == TargetPlatform.android) {
          fallbackSettings = AndroidSettings(
            accuracy: LocationAccuracy.medium,
            distanceFilter: 10,
            intervalDuration: const Duration(seconds: 2),
            timeLimit: const Duration(seconds: 3),
          );
        } else {
          fallbackSettings = const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 3),
          );
        }
        position = await Geolocator.getCurrentPosition(
          locationSettings: fallbackSettings,
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

    final validated = validatePosition(position);
    _cachedPosition = validated;
    _cachedAt = DateTime.now();
    return validated;
  }

  /// Validates security and integrity of a GPS position fix:
  /// - Blocks Mock Locations (Fake GPS spoofing)
  /// - Validates non-negative accuracy radius
  /// - Protects against device clock manipulation / future timestamps
  static Position validatePosition(Position position) {
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
