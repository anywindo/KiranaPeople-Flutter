import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kirana_people/data/models/shift_model.dart';
import 'package:kirana_people/data/models/attendance_event_model.dart';
import 'package:kirana_people/core/notifications/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NotificationService Tests', () {
    test('Notification preferences toggle correctly', () async {
      final service = NotificationService.instance;
      expect(await service.isEnabled(), isTrue);

      await service.setEnabled(false);
      expect(await service.isEnabled(), isFalse);

      await service.setEnabled(true);
      expect(await service.isEnabled(), isTrue);
    });

    test('Shift schedule calculations parse valid times', () {
      final shift = Shift(
        id: 1,
        name: 'Pagi',
        startTime: '08:00',
        endTime: '16:00',
        breakStartTime: '12:00',
        breakEndTime: '13:00',
        attendanceRuleEnabled: true,
        attendanceRuleMinutes: 15,
      );

      expect(shift.startTime, '08:00');
      expect(shift.endTime, '16:00');
      expect(shift.effectiveBreakStart, '12:00');
      expect(shift.effectiveBreakEnd, '13:00');
    });

    test('Attendance events distinguish completed phases', () {
      final events = [
        AttendanceEvent(
          id: 1,
          eventType: AttendanceEventType.startShift,
          timestamp: '2026-11-02T07:40:00Z',
        ),
      ];

      final hasStartedShift = events.any(
        (e) => e.eventType == AttendanceEventType.startShift,
      );
      final hasEndedShift = events.any(
        (e) => e.eventType == AttendanceEventType.endShift,
      );
      final hasEndedBreak = events.any(
        (e) => e.eventType == AttendanceEventType.endBreak,
      );

      expect(hasStartedShift, isTrue);
      expect(hasEndedShift, isFalse);
      expect(hasEndedBreak, isFalse);
    });

    test('Attendance submission event label and notification content format', () {
      const startShiftEvent = AttendanceEventType.startShift;
      const endShiftEvent = AttendanceEventType.endShift;
      const startBreakEvent = AttendanceEventType.startBreak;
      const endBreakEvent = AttendanceEventType.endBreak;

      expect(startShiftEvent.label, 'Masuk Kerja');
      expect(endShiftEvent.label, 'Pulang Kerja');
      expect(startBreakEvent.label, 'Mulai Istirahat');
      expect(endBreakEvent.label, 'Selesai Istirahat');

      // Geolocator returns UTC timestamps: e.g. 01:05 UTC should convert to 08:05 UTC+7 (WIB)
      final utcTimestamp = DateTime.utc(2026, 11, 2, 1, 5);
      final time = utcTimestamp.toUtc().add(const Duration(hours: 7));
      final hourStr = time.hour.toString().padLeft(2, '0');
      final minuteStr = time.minute.toString().padLeft(2, '0');
      final timeStr = '$hourStr:$minuteStr';

      expect(timeStr, '08:05');
      final expectedTitle = '✅ Presensi ${startShiftEvent.label} Berhasil';
      final expectedBody =
          'Presensi ${startShiftEvent.label} Anda telah berhasil dicatat pada pukul $timeStr WIB. Data telah tersinkronisasi.';

      expect(expectedTitle, '✅ Presensi Masuk Kerja Berhasil');
      expect(expectedBody, contains('08:05 WIB'));
    });
  });
}
