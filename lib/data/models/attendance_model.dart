import 'shift_model.dart';
import 'work_location_model.dart';
import 'attendance_event_model.dart';

class TodayAttendanceData {
  final String? date;
  final String? status;
  final String? nextAllowedAction;
  final bool? activeBreak;
  final Shift? shift;
  final List<Shift>? availableShifts;
  final WorkLocation? workLocation;
  final List<AttendanceEvent>? events;

  TodayAttendanceData({
    this.date,
    this.status,
    this.nextAllowedAction,
    this.activeBreak,
    this.shift,
    this.availableShifts,
    this.workLocation,
    this.events,
  });

  factory TodayAttendanceData.fromJson(Map<String, dynamic> json) {
    return TodayAttendanceData(
      date: json['date']?.toString(),
      status: json['status']?.toString(),
      nextAllowedAction: json['next_allowed_action']?.toString(),
      activeBreak: json['active_break'] == true,
      shift: json['shift'] != null && json['shift'] is Map<String, dynamic>
          ? Shift.fromJson(json['shift'] as Map<String, dynamic>)
          : null,
      availableShifts: json['available_shifts'] is List
          ? (json['available_shifts'] as List)
              .map((e) => Shift.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      workLocation: json['work_location'] != null && json['work_location'] is Map<String, dynamic>
          ? WorkLocation.fromJson(json['work_location'] as Map<String, dynamic>)
          : null,
      events: json['events'] is List
          ? (json['events'] as List)
              .map((e) => AttendanceEvent.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

class AttendanceRecord {
  final int id;
  final String date;
  final String? status;
  final Shift? shift;
  final List<AttendanceEvent> events;

  AttendanceRecord({
    required this.id,
    required this.date,
    this.status,
    this.shift,
    required this.events,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      date: json['date']?.toString() ?? '',
      status: json['status']?.toString(),
      shift: json['shift'] != null && json['shift'] is Map<String, dynamic>
          ? Shift.fromJson(json['shift'] as Map<String, dynamic>)
          : null,
      events: json['events'] is List
          ? (json['events'] as List)
              .map((e) => AttendanceEvent.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}
