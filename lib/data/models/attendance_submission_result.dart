import 'attendance_event_model.dart';

class AttendanceSubmissionResult {
  final AttendanceEventType action;
  final DateTime timestamp;
  final bool isWithinRadius;
  final double distance;
  final String locationName;
  final String? shiftName;
  final bool? isLate;

  const AttendanceSubmissionResult({
    required this.action,
    required this.timestamp,
    required this.isWithinRadius,
    required this.distance,
    required this.locationName,
    this.shiftName,
    this.isLate,
  });
}

