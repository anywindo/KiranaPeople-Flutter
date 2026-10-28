import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/core/network/api_exception.dart';
import 'package:kirana_people/data/models/attendance_event_model.dart';
import 'package:kirana_people/data/models/attendance_model.dart';
import 'package:kirana_people/data/repositories/attendance_repository.dart';
import 'package:kirana_people/providers/attendance_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimeoutMockRepository extends AttendanceRepository {
  bool submitCalled = false;
  bool checkCalled = false;

  @override
  Future<void> submitAttendanceEvent({
    required AttendanceEventType eventType,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    DateTime? deviceTimestamp,
    bool isMocked = false,
    bool? isDeviceRooted,
    dynamic photoFile,
    int? shiftId,
    String? notes,
  }) async {
    submitCalled = true;
    // Simulate Dio timeout exception converted by ApiClient
    throw ApiException(
      message: 'Koneksi ke server terputus (waktu habis). Silakan coba lagi.',
    );
  }

  @override
  Future<TodayAttendanceData> getTodayAttendance() async {
    checkCalled = true;
    return TodayAttendanceData(
      date: '2026-10-28',
      status: 'EXACT',
      events: [
        AttendanceEvent(
          eventType: AttendanceEventType.startShift,
          timestamp: '2026-10-28 09:45:00',
        ),
      ],
    );
  }
}

void main() {
  test('submitEvent auto-reconciles successfully when server timed out but recorded the event', () async {
    final mockRepo = TimeoutMockRepository();
    final container = ProviderContainer(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(todayAttendanceProvider.notifier);

    final result = await notifier.submitEvent(
      eventType: AttendanceEventType.startShift,
      latitude: -6.9,
      longitude: 107.6,
    );

    expect(mockRepo.submitCalled, isTrue);
    expect(mockRepo.checkCalled, isTrue);
    expect(result, isTrue, reason: 'Should return true because the event was already recorded by the server');
    expect(container.read(todayAttendanceProvider).submitError, isNull);
  });
}

