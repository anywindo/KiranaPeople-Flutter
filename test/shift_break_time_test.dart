import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/data/models/shift_model.dart';

void main() {
  group('Shift.isBeforeBreak and Shift.isBeforeBreakTime', () {
    test('Standard day shift (08:00 - 17:00, break 12:00)', () {
      final shift = Shift(
        id: 1,
        name: 'Regular',
        startTime: '08:00:00',
        endTime: '17:00:00',
        breakStartTime: '12:00:00',
        breakEndTime: '13:00:00',
      );

      // Morning before break: 08:30 -> true
      expect(shift.isBeforeBreak(DateTime(2026, 10, 28, 8, 30)), isTrue);
      // Just before break: 11:59 -> true
      expect(shift.isBeforeBreak(DateTime(2026, 10, 28, 11, 59)), isTrue);
      // Exactly at break: 12:00 -> false
      expect(shift.isBeforeBreak(DateTime(2026, 10, 28, 12, 0)), isFalse);
      // During break: 12:30 -> false
      expect(shift.isBeforeBreak(DateTime(2026, 10, 28, 12, 30)), isFalse);
      // After break: 14:00 -> false
      expect(shift.isBeforeBreak(DateTime(2026, 10, 28, 14, 0)), isFalse);
    });

    test('Overnight shift (20:00 - 04:00, break 00:30)', () {
      final shift = Shift(
        id: 2,
        name: 'Night',
        startTime: '20:00:00',
        endTime: '04:00:00',
        breakStartTime: '00:30:00',
        breakEndTime: '01:30:00',
      );

      // Evening shift start: 20:30 -> true
      expect(shift.isBeforeBreak(DateTime(2026, 10, 28, 20, 30)), isTrue);
      // Late night before midnight: 23:59 -> true
      expect(shift.isBeforeBreak(DateTime(2026, 10, 28, 23, 59)), isTrue);
      // Early morning before break: 00:15 -> true
      expect(shift.isBeforeBreak(DateTime(2026, 10, 29, 0, 15)), isTrue);
      // At break: 00:30 -> false
      expect(shift.isBeforeBreak(DateTime(2026, 10, 29, 0, 30)), isFalse);
      // After break: 01:45 -> false
      expect(shift.isBeforeBreak(DateTime(2026, 10, 29, 1, 45)), isFalse);
    });

    test('Shift with null breakStartTime calculates midpoint and works correctly', () {
      final shift = Shift(
        id: 3,
        name: 'Office',
        startTime: '08:00:00',
        endTime: '16:00:00',
      );
      // Midpoint: 8h duration / 2 - 30m = 3h30m -> 11:30
      expect(shift.effectiveBreakStart, equals('11:30'));
      expect(shift.isBeforeBreak(DateTime(2026, 10, 28, 11, 0)), isTrue);
      expect(shift.isBeforeBreak(DateTime(2026, 10, 28, 11, 30)), isFalse);
    });

    test('Shift.isBeforeBreakTime with null shift falls back to 12:00', () {
      expect(Shift.isBeforeBreakTime(null, DateTime(2026, 10, 28, 11, 59)), isTrue);
      expect(Shift.isBeforeBreakTime(null, DateTime(2026, 10, 28, 12, 0)), isFalse);
      expect(Shift.isBeforeBreakTime(null, DateTime(2026, 10, 28, 13, 0)), isFalse);
    });
  });
}
