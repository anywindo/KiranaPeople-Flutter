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
        'Device location service is disabled. Please enable GPS.',
      );
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Please enable it in system settings.',
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
          'Failed to acquire current GPS location. Please ensure GPS is active and you have good signal.',
        );
      }
    }

    if (position.isMocked) {
      throw Exception(
        'Mock location detected (Fake GPS). Please disable mock location apps to record attendance.',
      );
    }

    return position;
  }
}
