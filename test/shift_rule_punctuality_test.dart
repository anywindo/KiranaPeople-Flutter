import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/data/models/shift_model.dart';

void main() {
  group('Shift Rule Punctuality Logic Tests (Batas Waktu Shift Start)', () {
    test('Acceptance Criteria 1: 07:36 check-in with 08:00 shift & 15m rule is on-time (HIJAU)', () {
      final shift = Shift(
        id: 1,
        name: 'Pagi',
        startTime: '08:00:00',
        endTime: '16:00:00',
        attendanceRuleEnabled: true,
        attendanceRuleMinutes: 15,
      );

      final isLate = shift.isStartLate('07:36');
      expect(isLate, isFalse, reason: 'Presensi 07:36 sebelum batas 07:45 harus tepat waktu (hijau)');
    });

    test('Acceptance Criteria 2: 07:46 check-in with 08:00 shift & 15m rule is late (TIDAK HIJAU)', () {
      final shift = Shift(
        id: 1,
        name: 'Pagi',
        startTime: '08:00:00',
        endTime: '16:00:00',
        attendanceRuleEnabled: true,
        attendanceRuleMinutes: 15,
      );

      final isLate = shift.isStartLate('07:46');
      expect(isLate, isTrue, reason: 'Presensi 07:46 setelah batas 07:45 harus terlambat (tidak hijau)');
    });

    test('Boundary comparison at cutoff: 07:44 vs 07:45', () {
      final shift = Shift(
        id: 1,
        name: 'Pagi',
        startTime: '08:00:00',
        endTime: '16:00:00',
        attendanceRuleEnabled: true,
        attendanceRuleMinutes: 15,
      );

      // Cutoff is 07:45. Presensi at 07:44 is before cutoff -> on time.
      expect(shift.isStartLate('07:44'), isFalse);
      // Presensi at 07:45 or after is at/past cutoff -> late.
      expect(shift.isStartLate('07:45'), isTrue);
      // Presensi at 07:48 (screenshot scenario) is late.
      expect(shift.isStartLate('07:48'), isTrue);
      // Presensi at 08:00 is late.
      expect(shift.isStartLate('08:00'), isTrue);
    });

    test('When Batas Waktu Shift Start is disabled, 07:46 is on-time, 08:01 is late', () {
      final shift = Shift(
        id: 1,
        name: 'Pagi',
        startTime: '08:00:00',
        endTime: '16:00:00',
        attendanceRuleEnabled: false,
        attendanceRuleMinutes: 15,
      );

      // Without rule, cutoff is scheduled shift start 08:00
      expect(shift.isStartLate('07:46'), isFalse, reason: '07:46 is before 08:00');
      expect(shift.isStartLate('08:00'), isFalse, reason: '08:00 is exact start time');
      expect(shift.isStartLate('08:01'), isTrue, reason: '08:01 is past 08:00');
    });

    test('Static Shift.isShiftStartLate with null or empty parameters fails safe', () {
      expect(Shift.isShiftStartLate(actualTime: null, scheduledTime: '08:00'), isFalse);
      expect(Shift.isShiftStartLate(actualTime: '07:30', scheduledTime: null), isFalse);
      expect(Shift.isShiftStartLate(actualTime: 'invalid', scheduledTime: '08:00'), isFalse);
    });

    test('Overnight shift crossing midnight (e.g., 00:10 shift start, 15m rule -> cutoff 23:55)', () {
      final nightShift = Shift(
        id: 2,
        name: 'Malam',
        startTime: '00:10:00',
        endTime: '08:00:00',
        attendanceRuleEnabled: true,
        attendanceRuleMinutes: 15,
      );

      // 23:50 is 20m before shift (before cutoff 23:55) -> on time
      expect(nightShift.isStartLate('23:50'), isFalse);
      // 23:55 is exact cutoff -> late
      expect(nightShift.isStartLate('23:55'), isTrue);
      // 23:56 is after cutoff -> late
      expect(nightShift.isStartLate('23:56'), isTrue);
      // 00:05 is 5m before shift start (after cutoff) -> late
      expect(nightShift.isStartLate('00:05'), isTrue);
    });

    test('Shift.fromJson correctly parses attendance rule properties', () {
      final jsonWithRule = {
        'id': 10,
        'name': 'Siang',
        'start_time': '13:00:00',
        'end_time': '21:00:00',
        'attendance_rule_enabled': true,
        'attendance_rule_minutes': 20,
      };

      final shift = Shift.fromJson(jsonWithRule);
      expect(shift.attendanceRuleEnabled, isTrue);
      expect(shift.attendanceRuleMinutes, equals(20));

      // Cutoff is 13:00 - 20m = 12:40
      expect(shift.isStartLate('12:35'), isFalse);
      expect(shift.isStartLate('12:40'), isTrue);
      expect(shift.isStartLate('12:45'), isTrue);
    });
  });
}

