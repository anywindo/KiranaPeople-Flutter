import '../../../data/models/attendance_event_model.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/shift_model.dart';

class AttendanceEventTimeline {
  final AttendanceEvent? startShiftEvent;
  final AttendanceEvent? endShiftEvent;
  final AttendanceEvent? startBreakEvent;
  final AttendanceEvent? endBreakEvent;

  final String? checkInTime;
  final String? checkOutTime;
  final String? startBreakTime;
  final String? endBreakTime;

  final bool hasStartedShift;
  final bool isCheckInLate;
  final bool hasEndedShift;
  final bool hasStartedBreak;
  final bool hasEndedBreak;
  final bool isOnBreak;

  const AttendanceEventTimeline({
    this.startShiftEvent,
    this.endShiftEvent,
    this.startBreakEvent,
    this.endBreakEvent,
    this.checkInTime,
    this.checkOutTime,
    this.startBreakTime,
    this.endBreakTime,
    required this.hasStartedShift,
    required this.isCheckInLate,
    required this.hasEndedShift,
    required this.hasStartedBreak,
    required this.hasEndedBreak,
    required this.isOnBreak,
  });

  factory AttendanceEventTimeline.fromData({
    required TodayAttendanceData? data,
    required Shift? selectedShift,
  }) {
    final events = data?.events ?? [];

    String? checkInTime;
    String? checkOutTime;
    String? startBreakTime;
    String? endBreakTime;

    AttendanceEvent? startShiftEvent;
    AttendanceEvent? endShiftEvent;
    AttendanceEvent? startBreakEvent;
    AttendanceEvent? endBreakEvent;

    for (final e in events) {
      final dt = DateTime.tryParse(e.timestamp);
      final localDt = dt != null ? (dt.isUtc ? dt.toLocal() : dt) : null;
      final formattedTime = localDt != null
          ? '${localDt.hour.toString().padLeft(2, '0')}:${localDt.minute.toString().padLeft(2, '0')}'
          : e.timestamp;

      if (e.eventType == AttendanceEventType.startShift) {
        startShiftEvent = e;
        checkInTime = formattedTime;
      } else if (e.eventType == AttendanceEventType.endShift) {
        endShiftEvent = e;
        checkOutTime = formattedTime;
      } else if (e.eventType == AttendanceEventType.startBreak) {
        startBreakEvent = e;
        startBreakTime = formattedTime;
      } else if (e.eventType == AttendanceEventType.endBreak) {
        endBreakEvent = e;
        endBreakTime = formattedTime;
      }
    }

    final hasStartedShift = startShiftEvent != null;
    final isCheckInLate = Shift.isShiftStartLate(
      actualTime: checkInTime,
      scheduledTime: selectedShift?.startTime ?? '08:00',
      ruleEnabled: selectedShift?.attendanceRuleEnabled ??
          data?.attendanceRuleEnabled ??
          true,
      ruleMinutes: selectedShift?.attendanceRuleMinutes ??
          data?.attendanceRuleMinutes ??
          15,
    );
    final hasEndedShift = endShiftEvent != null ||
        data?.status?.toUpperCase() == 'COMPLETED' ||
        data?.status?.toUpperCase() == 'SELESAI';
    final hasStartedBreak = startBreakEvent != null;
    final hasEndedBreak = endBreakEvent != null;
    final isOnBreak = hasStartedBreak && !hasEndedBreak;

    return AttendanceEventTimeline(
      startShiftEvent: startShiftEvent,
      endShiftEvent: endShiftEvent,
      startBreakEvent: startBreakEvent,
      endBreakEvent: endBreakEvent,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      startBreakTime: startBreakTime,
      endBreakTime: endBreakTime,
      hasStartedShift: hasStartedShift,
      isCheckInLate: isCheckInLate,
      hasEndedShift: hasEndedShift,
      hasStartedBreak: hasStartedBreak,
      hasEndedBreak: hasEndedBreak,
      isOnBreak: isOnBreak,
    );
  }

  static AttendanceEventType resolveTargetAction({
    required TodayAttendanceData? data,
    required int activeSegment,
  }) {
    final nextAllowed = data?.nextAllowedAction;
    if (nextAllowed != null && nextAllowed.isNotEmpty) {
      return AttendanceEventType.fromString(nextAllowed);
    }

    final events = data?.events ?? [];
    if (events.isEmpty) return AttendanceEventType.startShift;

    final hasStartShift = events.any(
      (e) => e.eventType == AttendanceEventType.startShift,
    );
    final hasStartBreak = events.any(
      (e) => e.eventType == AttendanceEventType.startBreak,
    );
    final hasEndBreak = events.any(
      (e) => e.eventType == AttendanceEventType.endBreak,
    );
    final hasEndShift = events.any(
      (e) => e.eventType == AttendanceEventType.endShift,
    );

    if (hasEndShift) return AttendanceEventType.startShift;

    if (activeSegment == 1) {
      // Istirahat Mode
      if (hasStartBreak && !hasEndBreak) {
        return AttendanceEventType.endBreak;
      }
      return AttendanceEventType.startBreak;
    } else {
      // Kerja Mode
      if (!hasStartShift) {
        return AttendanceEventType.startShift;
      }
      return AttendanceEventType.endShift;
    }
  }
}

