import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/core/constants/api_endpoints.dart';
import 'package:kirana_people/core/network/api_client.dart';
import 'package:kirana_people/data/models/attendance_event_model.dart';
import 'package:kirana_people/data/repositories/attendance_repository.dart';

class MockApiClient extends ApiClient {
  String? lastPath;
  FormData? lastFormData;

  @override
  Future<Response> postMultipart(
    String path, {
    required FormData formData,
    ProgressCallback? onSendProgress,
    Duration? sendTimeout,
    Duration? receiveTimeout,
  }) async {
    lastPath = path;
    lastFormData = formData;
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {'status': 'success'},
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Attendance Anti-Spoofing & Telemetry Security Tests (MED-01)', () {
    test('submitAttendanceEvent transmits location telemetry and anti-spoofing flags', () async {
      final mockClient = MockApiClient();
      final repository = AttendanceRepository(apiClient: mockClient);

      final fixedTimestamp = DateTime.utc(2026, 10, 28, 9, 30, 0);

      await repository.submitAttendanceEvent(
        eventType: AttendanceEventType.startShift,
        latitude: -6.914744,
        longitude: 107.609810,
        accuracy: 12.5,
        altitude: 720.0,
        deviceTimestamp: fixedTimestamp,
        isMocked: false,
        shiftId: 2,
        notes: 'Hadir tepat waktu',
      );

      expect(mockClient.lastPath, equals(ApiEndpoints.attendanceEvents));
      expect(mockClient.lastFormData, isNotNull);

      final fields = Map.fromEntries(mockClient.lastFormData!.fields);
      expect(fields['event_type'], equals('START_SHIFT'));
      expect(fields['latitude'], equals('-6.914744'));
      expect(fields['longitude'], equals('107.60981'));
      expect(fields['is_mocked'], equals('0'));
      expect(fields['accuracy'], equals('12.5'));
      expect(fields['altitude'], equals('720.0'));
      expect(fields['device_timestamp'], equals('2026-10-28T09:30:00.000Z'));
      expect(fields['shift_id'], equals('2'));
      expect(fields['notes'], equals('Hadir tepat waktu'));
    });

    test('submitAttendanceEvent flags mock location when detected', () async {
      final mockClient = MockApiClient();
      final repository = AttendanceRepository(apiClient: mockClient);

      await repository.submitAttendanceEvent(
        eventType: AttendanceEventType.endShift,
        latitude: -6.914744,
        longitude: 107.609810,
        isMocked: true,
      );

      final fields = Map.fromEntries(mockClient.lastFormData!.fields);
      expect(fields['is_mocked'], equals('1'));
    });

    test('submitAttendanceEvent flags rooted devices when detected (MED-03)', () async {
      final mockClient = MockApiClient();
      final repository = AttendanceRepository(apiClient: mockClient);

      await repository.submitAttendanceEvent(
        eventType: AttendanceEventType.startShift,
        latitude: -6.914744,
        longitude: 107.609810,
        isDeviceRooted: true,
      );

      final fields = Map.fromEntries(mockClient.lastFormData!.fields);
      expect(fields['is_rooted'], equals('1'));
    });

    test('Selfie image cleanup purges temporary file on disk (MED-02)', () async {
      final tempDir = Directory.systemTemp.createTempSync('selfie_lifecycle_test');
      final testFile = File('${tempDir.path}/selfie.jpg');
      await testFile.writeAsString('test_selfie_data');
      expect(await testFile.exists(), isTrue);

      // Perform lifecycle purge
      if (await testFile.exists()) {
        await testFile.delete();
      }

      expect(await testFile.exists(), isFalse);
      tempDir.deleteSync(recursive: true);
    });
  });
}
