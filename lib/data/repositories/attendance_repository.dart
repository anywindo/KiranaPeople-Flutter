import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attendance_model.dart';
import '../models/attendance_event_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/security/device_security_service.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

class AttendanceRepository {
  final ApiClient _apiClient;

  AttendanceRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<TodayAttendanceData> getTodayAttendance() async {
    final response = await _apiClient.get(ApiEndpoints.todayAttendance);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final payload = data['data'] ?? data;
      if (payload is Map<String, dynamic>) {
        return TodayAttendanceData.fromJson(payload);
      }
    }
    throw Exception('Gagal memuat status presensi hari ini.');
  }

  Future<void> submitAttendanceEvent({
    required AttendanceEventType eventType,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    DateTime? deviceTimestamp,
    bool isMocked = false,
    bool? isDeviceRooted,
    File? photoFile,
    int? shiftId,
    String? notes,
  }) async {
    final formDataMap = <String, dynamic>{
      'event_type': eventType.value,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'is_mocked': isMocked ? '1' : '0',
    };

    // Device integrity telemetry: always sent explicitly (never omitted) so the
    // backend can distinguish clean / compromised / unverified devices.
    final report = await DeviceSecurityService().getReport();
    formDataMap.addAll(report.toFormFields());
    if (isDeviceRooted != null) {
      formDataMap['is_rooted'] = isDeviceRooted ? '1' : '0';
    }
    if (report.shouldBlock) {
      throw Exception(
        'Perangkat tidak lolos pemeriksaan keamanan. Presensi tidak dapat dilakukan pada perangkat yang dimodifikasi.',
      );
    }

    if (accuracy != null) {
      formDataMap['accuracy'] = accuracy.toString();
    }

    if (altitude != null) {
      formDataMap['altitude'] = altitude.toString();
    }

    if (deviceTimestamp != null) {
      formDataMap['device_timestamp'] =
          deviceTimestamp.toUtc().toIso8601String();
    }

    if (shiftId != null) {
      formDataMap['shift_id'] = shiftId.toString();
    }

    if (notes != null && notes.isNotEmpty) {
      formDataMap['notes'] = notes;
    }

    if (photoFile != null && await photoFile.exists()) {
      formDataMap['selfie'] = await MultipartFile.fromFile(
        photoFile.path,
        filename: 'selfie.jpg',
      );
    }

    final formData = FormData.fromMap(formDataMap);
    await _apiClient.postMultipart(
      ApiEndpoints.attendanceEvents,
      formData: formData,
    );
  }

  Future<List<AttendanceRecord>> getAttendanceHistory({
    int page = 1,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, dynamic>{'page': page};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (startDate != null && startDate.isNotEmpty) {
      queryParams['start_date'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      queryParams['end_date'] = endDate;
    }

    final response = await _apiClient.get(
      ApiEndpoints.attendanceHistory,
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final listData = data['data'];
      if (listData is List) {
        return listData
            .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }
}
