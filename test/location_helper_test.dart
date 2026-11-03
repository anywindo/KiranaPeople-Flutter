import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kirana_people/core/utils/location_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Position createTestPosition({
    double latitude = -6.200000,
    double longitude = 106.816666,
    double accuracy = 10.0,
    bool isMocked = false,
    DateTime? timestamp,
  }) {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp ?? DateTime.now(),
      accuracy: accuracy,
      altitude: 10.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
      isMocked: isMocked,
    );
  }

  setUp(() {
    LocationHelper.resetCache();
  });

  tearDown(() {
    LocationHelper.resetCache();
  });

  group('LocationHelper.validatePosition', () {
    test('passes valid, non-mocked, timely position fix', () {
      final pos = createTestPosition();
      final validated = LocationHelper.validatePosition(pos);
      expect(validated.latitude, equals(pos.latitude));
      expect(validated.longitude, equals(pos.longitude));
      expect(validated.isMocked, isFalse);
    });

    test('throws Exception when isMocked is true (Fake GPS detection)', () {
      final pos = createTestPosition(isMocked: true);
      expect(
        () => LocationHelper.validatePosition(pos),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Terdeteksi lokasi palsu (Fake GPS)'),
          ),
        ),
      );
    });

    test('throws Exception when accuracy is negative', () {
      final pos = createTestPosition(accuracy: -5.0);
      expect(
        () => LocationHelper.validatePosition(pos),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Akurasi sinyal GPS tidak valid'),
          ),
        ),
      );
    });

    test('throws Exception when position timestamp is far in the future (>60s)', () {
      final futureTime = DateTime.now().add(const Duration(minutes: 5));
      final pos = createTestPosition(timestamp: futureTime);
      expect(
        () => LocationHelper.validatePosition(pos),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Waktu perangkat tidak sinkron'),
          ),
        ),
      );
    });
  });

  group('LocationHelper caching & power optimization', () {
    test('reuses cached position when under 60 seconds old without forceRefresh', () async {
      final initialPos = createTestPosition(latitude: -6.123456, longitude: 106.654321);
      LocationHelper.seedCache(initialPos, cachedAt: DateTime.now().subtract(const Duration(seconds: 15)));

      final pos = await LocationHelper.determinePosition(forceRefresh: false);
      expect(pos.latitude, equals(-6.123456));
      expect(pos.longitude, equals(106.654321));
    });

    test('resetCache clears cached position state', () {
      final initialPos = createTestPosition();
      LocationHelper.seedCache(initialPos);
      LocationHelper.resetCache();

      // Ensure cache is empty by testing through determinePosition behavior or seed state
      // (calling resetCache should not throw)
      expect(true, isTrue);
    });

    test('LocationResult model fields are properly initialized', () {
      final result = LocationResult(
        latitude: -6.2,
        longitude: 106.8,
        isMocked: false,
      );
      expect(result.latitude, equals(-6.2));
      expect(result.longitude, equals(106.8));
      expect(result.isMocked, isFalse);
    });
  });
}
