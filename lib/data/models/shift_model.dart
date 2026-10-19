class Shift {
  final int id;
  final String name;
  final String startTime;
  final String endTime;
  final String? breakStartTime;
  final String? breakEndTime;

  Shift({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.breakStartTime,
    this.breakEndTime,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      breakStartTime: json['break_start_time']?.toString() ?? json['break_start']?.toString(),
      breakEndTime: json['break_end_time']?.toString() ?? json['break_end']?.toString(),
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
}
