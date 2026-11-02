class Shift {
  final int id;
  final String name;
  final String startTime;
  final String endTime;
  final String? breakStartTime;
  final String? breakEndTime;
  final bool? attendanceRuleEnabled;
  final int? attendanceRuleMinutes;

  Shift({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.breakStartTime,
    this.breakEndTime,
    this.attendanceRuleEnabled,
    this.attendanceRuleMinutes,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    bool? ruleEnabled;
    if (json.containsKey('attendance_rule_enabled')) {
      final raw = json['attendance_rule_enabled'];
      ruleEnabled = raw == true || raw?.toString() == '1' || raw?.toString().toLowerCase() == 'true';
    }

    int? ruleMinutes;
    if (json.containsKey('attendance_rule_minutes')) {
      final raw = json['attendance_rule_minutes'];
      ruleMinutes = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
    }

    return Shift(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      breakStartTime: json['break_start_time']?.toString() ?? json['break_start']?.toString(),
      breakEndTime: json['break_end_time']?.toString() ?? json['break_end']?.toString(),
      attendanceRuleEnabled: ruleEnabled,
      attendanceRuleMinutes: ruleMinutes,
    );
  }

  Shift copyWith({
    int? id,
    String? name,
    String? startTime,
    String? endTime,
    String? breakStartTime,
    String? breakEndTime,
    bool? attendanceRuleEnabled,
    int? attendanceRuleMinutes,
  }) {
    return Shift(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breakStartTime: breakStartTime ?? this.breakStartTime,
      breakEndTime: breakEndTime ?? this.breakEndTime,
      attendanceRuleEnabled: attendanceRuleEnabled ?? this.attendanceRuleEnabled,
      attendanceRuleMinutes: attendanceRuleMinutes ?? this.attendanceRuleMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'start_time': startTime,
      'end_time': endTime,
      'break_start_time': breakStartTime,
      'break_end_time': breakEndTime,
      if (attendanceRuleEnabled != null) 'attendance_rule_enabled': attendanceRuleEnabled,
      if (attendanceRuleMinutes != null) 'attendance_rule_minutes': attendanceRuleMinutes,
    };
  }

  /// Effective break start time "HH:mm"
  String get effectiveBreakStart {
    if (breakStartTime != null && breakStartTime!.trim().isNotEmpty) {
      final trimmed = breakStartTime!.trim();
      return trimmed.length >= 5 ? trimmed.substring(0, 5) : trimmed;
    }
    // Midpoint minus 30 minutes calculation
    int startH = int.tryParse(startTime.length >= 2 ? startTime.substring(0, 2) : '') ?? 8;
    int startM = int.tryParse(startTime.length >= 5 ? startTime.substring(3, 5) : '') ?? 0;
    int endH = int.tryParse(endTime.length >= 2 ? endTime.substring(0, 2) : '') ?? ((startH + 8) % 24);
    int endM = int.tryParse(endTime.length >= 5 ? endTime.substring(3, 5) : '') ?? 0;

    int duration = (endH * 60 + endM) - (startH * 60 + startM);
    if (duration <= 0) {
      duration += 24 * 60;
    }
    int midpoint = (startH * 60 + startM) + (duration ~/ 2) - 30;
    int bHour = (midpoint ~/ 60) % 24;
    int bMin = midpoint % 60;
    return '${bHour.toString().padLeft(2, '0')}:${bMin.toString().padLeft(2, '0')}';
  }

  /// Effective break end time "HH:mm"
  String get effectiveBreakEnd {
    if (breakEndTime != null && breakEndTime!.trim().isNotEmpty) {
      final trimmed = breakEndTime!.trim();
      return trimmed.length >= 5 ? trimmed.substring(0, 5) : trimmed;
    }
    // Default to 1 hour after effectiveBreakStart
    final startStr = effectiveBreakStart;
    final h = int.tryParse(startStr.length >= 2 ? startStr.substring(0, 2) : '') ?? 12;
    final m = int.tryParse(startStr.length >= 5 ? startStr.substring(3, 5) : '') ?? 0;
    final endH = (h + 1) % 24;
    return '${endH.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Returns whether [currentTime] (defaults to DateTime.now()) is before the scheduled break start time.
  bool isBeforeBreak([DateTime? currentTime]) {
    final now = currentTime ?? DateTime.now();
    final breakStr = effectiveBreakStart;
    final startStr = startTime;

    try {
      final breakParts = breakStr.split(':');
      final breakMinutes = int.parse(breakParts[0]) * 60 + int.parse(breakParts[1]);

      final startParts = startStr.split(':');
      final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);

      final nowMinutes = now.hour * 60 + now.minute;

      if (breakMinutes >= startMinutes) {
        // Normal daytime shift: break is on the same calendar day as shift start
        return nowMinutes < breakMinutes;
      } else {
        // Overnight shift: break is on the next calendar day
        if (nowMinutes >= startMinutes) {
          return true; // Still on the shift-start evening, break is after midnight
        }
        return nowMinutes < breakMinutes;
      }
    } catch (_) {
      return false;
    }
  }

  /// Helper to check whether it is before break time for a shift (or default 12:00 if shift is null).
  static bool isBeforeBreakTime(Shift? shift, [DateTime? currentTime]) {
    if (shift != null) {
      return shift.isBeforeBreak(currentTime);
    }
    final now = currentTime ?? DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    return nowMinutes < (12 * 60); // Default break start at 12:00
  }

  /// Evaluates whether an actual clock-in time is late based on shift start time and Batas Waktu Shift Start rule.
  ///
  /// - When [ruleEnabled] is true with [ruleMinutes] > 0:
  ///   The cutoff is [scheduledTime] minus [ruleMinutes].
  ///   Presensi must be made BEFORE the cutoff time (actual < cutoff).
  ///   Presensi at or after cutoff (actual >= cutoff) is considered late (returns true).
  ///   Example: Shift 08:00 with 15 min cutoff -> deadline is 07:45.
  ///   07:36 is before 07:45 -> on-time (false).
  ///   07:46 is after 07:45 -> late (true).
  ///   07:45 is at deadline -> late (true).
  ///
  /// - When [ruleEnabled] is false:
  ///   Presensi after [scheduledTime] is late (actual > scheduledTime).
  static bool isShiftStartLate({
    required String? actualTime,
    required String? scheduledTime,
    bool ruleEnabled = true,
    int ruleMinutes = 15,
  }) {
    if (actualTime == null || scheduledTime == null || scheduledTime.isEmpty) {
      return false;
    }
    try {
      final actualParts = actualTime.split(':');
      final schedParts = scheduledTime.split(':');
      final actualMin =
          int.parse(actualParts[0]) * 60 + int.parse(actualParts[1]);
      final schedMin =
          int.parse(schedParts[0]) * 60 + int.parse(schedParts[1]);

      // Calculate signed difference in minutes from scheduled start (-720..+720)
      var diff = actualMin - schedMin;
      if (diff < -720) {
        diff += 1440;
      } else if (diff > 720) {
        diff -= 1440;
      }

      if (ruleEnabled && ruleMinutes > 0) {
        // Cutoff relative to scheduled start is -ruleMinutes.
        // Clocking in at -ruleMinutes or later is late (diff >= -ruleMinutes).
        // Clocking in before -ruleMinutes is on time (diff < -ruleMinutes).
        return diff >= -ruleMinutes;
      } else {
        // Clocking in after scheduled start time is late (diff > 0).
        return diff > 0;
      }
    } catch (_) {
      return false;
    }
  }

  /// Convenience instance method for this shift instance.
  bool isStartLate(
    String? actualTime, {
    bool? ruleEnabled,
    int? ruleMinutes,
  }) {
    return isShiftStartLate(
      actualTime: actualTime,
      scheduledTime: startTime,
      ruleEnabled: ruleEnabled ?? attendanceRuleEnabled ?? true,
      ruleMinutes: ruleMinutes ?? attendanceRuleMinutes ?? 15,
    );
  }
}
