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
      throw Exception('Layanan GPS/Lokasi perangkat dinonaktifkan. Silakan aktifkan GPS.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin akses lokasi ditolak oleh pengguna.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin akses lokasi ditolak permanen. Buka pengaturan untuk mengaktifkan.');
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
        throw Exception('Gagal mendapatkan koordinat GPS terkini. Pastikan GPS aktif dan berada di area dengan sinyal yang baik.');
      }
    }

    if (position.isMocked) {
      throw Exception('Terdeteksi lokasi palsu (Fake GPS / Mock Location). Harap nonaktifkan aplikasi pemalsu lokasi untuk melakukan presensi.');
    }

    return position;
  }
}
