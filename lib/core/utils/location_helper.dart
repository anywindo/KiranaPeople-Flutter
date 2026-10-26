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
  static Future<Position> determinePosition() async {
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

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (_) {
      // Fallback: If live GPS times out (e.g. indoors), only accept recent cached position (max 10 minutes old)
      final lastPos = await Geolocator.getLastKnownPosition();
      final now = DateTime.now();
      if (lastPos != null &&
          now.difference(lastPos.timestamp).inMinutes.abs() <= 10) {
        position = lastPos;
      } else {
        throw Exception(
          'Gagal mendapatkan lokasi GPS terkini. Pastikan GPS aktif dan sinyal memadai.',
        );
      }
    }

    if (position.isMocked) {
      throw Exception(
        'Terdeteksi lokasi palsu (Fake GPS). Harap nonaktifkan aplikasi Fake GPS untuk presensi.',
      );
    }

    return position;
  }
}
