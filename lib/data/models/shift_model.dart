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
}
