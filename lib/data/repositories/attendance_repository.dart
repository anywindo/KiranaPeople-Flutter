import 'dart:io';
import 'package:dio/dio.dart';
import '../models/attendance_model.dart';
import '../models/attendance_event_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';

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
    File? photoFile,
    String? notes,
  }) async {
    final formDataMap = <String, dynamic>{
      'event_type': eventType.value,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };

    if (notes != null && notes.isNotEmpty) {
      formDataMap['notes'] = notes;
    }

    if (photoFile != null && await photoFile.exists()) {
      final fileName = photoFile.path.split('/').last;
      formDataMap['photo'] = await MultipartFile.fromFile(
        photoFile.path,
        filename: fileName,
      );
    }

    final formData = FormData.fromMap(formDataMap);
    await _apiClient.postMultipart(
      ApiEndpoints.attendanceEvents,
      formData: formData,
    );
  }

  Future<List<AttendanceRecord>> getAttendanceHistory({int page = 1}) async {
    final response = await _apiClient.get(
      ApiEndpoints.attendanceHistory,
      queryParameters: {'page': page},
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
