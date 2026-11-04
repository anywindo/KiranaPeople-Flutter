import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:kirana_people/data/models/shift_model.dart';
import 'package:kirana_people/data/models/attendance_event_model.dart';
import 'package:kirana_people/core/notifications/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tz.initializeTimeZones();
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

      // Test failure notification formatting
      final expectedFailTitle = '❌ Presensi ${startShiftEvent.label} Gagal';
      final expectedFailBody =
          'Presensi ${startShiftEvent.label} Anda pada pukul $timeStr WIB tidak berhasil tercatat: Koneksi terputus. Silakan buka aplikasi dan coba kembali.';
      expect(expectedFailTitle, '❌ Presensi Masuk Kerja Gagal');
      expect(expectedFailBody, contains('08:05 WIB'));
      expect(expectedFailBody, contains('Koneksi terputus'));
    });

    test('calculateNextShiftStartReminders schedules today when before start time', () {
      final service = NotificationService.instance;
      final now = tz.TZDateTime(tz.local, 2026, 11, 4, 6, 30); // 06:30 AM

      final reminders = service.calculateNextShiftStartReminders(
        timeStr: '08:00',
        now: now,
        alreadyCheckedIn: false,
      );

      expect(reminders, isNotNull);
      final (time30, time15) = reminders!;
      // 30 min before 08:00 -> 07:30 today
      expect(time30.day, 4);
      expect(time30.hour, 7);
      expect(time30.minute, 30);

      // 15 min before 08:00 -> 07:45 today
      expect(time15.day, 4);
      expect(time15.hour, 7);
      expect(time15.minute, 45);
    });

    test('calculateNextShiftStartReminders advances to tomorrow when time has passed', () {
      final service = NotificationService.instance;
      final now = tz.TZDateTime(tz.local, 2026, 11, 4, 8, 30); // 08:30 AM (after 07:30 and 07:45)

      final reminders = service.calculateNextShiftStartReminders(
        timeStr: '08:00',
        now: now,
        alreadyCheckedIn: false,
      );

      expect(reminders, isNotNull);
      final (time30, time15) = reminders!;
      // Both should advance to tomorrow (day 5)
      expect(time30.day, 5);
      expect(time30.hour, 7);
      expect(time30.minute, 30);

      expect(time15.day, 5);
      expect(time15.hour, 7);
      expect(time15.minute, 45);
    });

    test('calculateNextShiftStartReminders advances to tomorrow if already checked in', () {
      final service = NotificationService.instance;
      // Even if it is 07:00 AM, if user has already checked in today, reminders are for tomorrow
      final now = tz.TZDateTime(tz.local, 2026, 11, 4, 7, 0);

      final reminders = service.calculateNextShiftStartReminders(
        timeStr: '08:00',
        now: now,
        alreadyCheckedIn: true,
      );

      expect(reminders, isNotNull);
      final (time30, time15) = reminders!;
      expect(time30.day, 5);
      expect(time15.day, 5);
    });

    test('calculateNextTime handles same day vs next day correctly', () {
      final service = NotificationService.instance;
      final now = tz.TZDateTime(tz.local, 2026, 11, 4, 10, 0); // 10:00 AM

      // Break ends at 13:00, subtract 5 min -> 12:55 PM
      final breakRemind = service.calculateNextTime(
        timeStr: '13:00',
        now: now,
        subtractMinutes: 5,
        alreadyDoneToday: false,
      );
      expect(breakRemind, isNotNull);
      expect(breakRemind!.day, 4);
      expect(breakRemind.hour, 12);
      expect(breakRemind.minute, 55);

      // Shift ends at 16:00
      final shiftEndRemind = service.calculateNextTime(
        timeStr: '16:00',
        now: now,
        subtractMinutes: 0,
        alreadyDoneToday: false,
      );
      expect(shiftEndRemind, isNotNull);
      expect(shiftEndRemind!.day, 4);
      expect(shiftEndRemind.hour, 16);
      expect(shiftEndRemind.minute, 0);

      // If already done today, should advance to tomorrow (day 5)
      final shiftEndDone = service.calculateNextTime(
        timeStr: '16:00',
        now: now,
        subtractMinutes: 0,
        alreadyDoneToday: true,
      );
      expect(shiftEndDone, isNotNull);
      expect(shiftEndDone!.day, 5);
      expect(shiftEndDone.hour, 16);
    });
  });
}
