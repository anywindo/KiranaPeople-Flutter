enum AttendanceEventType {
  startShift('START_SHIFT', 'Masuk Kerja'),
  startBreak('START_BREAK', 'Mulai Istirahat'),
  endBreak('END_BREAK', 'Selesai Istirahat'),
  endShift('END_SHIFT', 'Pulang Kerja');

  final String value;
  final String label;
  const AttendanceEventType(this.value, this.label);

  static AttendanceEventType fromString(String raw) {
    for (final type in AttendanceEventType.values) {
      if (type.value.toUpperCase() == raw.toUpperCase()) {
        return type;
      }
    }
    return AttendanceEventType.startShift;
  }
}

class AttendanceEvent {
  final int? id;
  final AttendanceEventType eventType;
  final String timestamp;
  final double? latitude;
  final double? longitude;
  final String? selfieUrl;
  final String? notes;

  AttendanceEvent({
    this.id,
    required this.eventType,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.selfieUrl,
    this.notes,
  });

  factory AttendanceEvent.fromJson(Map<String, dynamic> json) {
    return AttendanceEvent(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      eventType: AttendanceEventType.fromString(json['event_type']?.toString() ?? ''),
      timestamp: json['timestamp']?.toString() ?? '',
      latitude: json['latitude'] is num
          ? (json['latitude'] as num).toDouble()
          : double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: json['longitude'] is num
          ? (json['longitude'] as num).toDouble()
          : double.tryParse(json['longitude']?.toString() ?? ''),
      selfieUrl: json['selfie_url']?.toString() ?? json['photo_url']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_type': eventType.value,
      'timestamp': timestamp,
      'latitude': latitude,
      'longitude': longitude,
      'selfie_url': selfieUrl,
      'notes': notes,
    };
  }
}
