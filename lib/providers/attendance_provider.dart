import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/attendance_model.dart';
import '../data/models/attendance_event_model.dart';
import '../data/repositories/attendance_repository.dart';
import '../core/utils/location_helper.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

class TodayAttendanceState {
  final AsyncValue<TodayAttendanceData> data;
  final bool isSubmitting;
  final String? submitError;

  const TodayAttendanceState({
    this.data = const AsyncValue.loading(),
    this.isSubmitting = false,
    this.submitError,
  });

  TodayAttendanceState copyWith({
    AsyncValue<TodayAttendanceData>? data,
    bool? isSubmitting,
    String? submitError,
    bool clearError = false,
  }) {
    return TodayAttendanceState(
      data: data ?? this.data,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearError ? null : (submitError ?? this.submitError),
    );
  }
}

class TodayAttendanceNotifier extends Notifier<TodayAttendanceState> {
  late final AttendanceRepository _repository;

  @override
  TodayAttendanceState build() {
    _repository = ref.read(attendanceRepositoryProvider);
    Future.microtask(() => refresh());
    return const TodayAttendanceState();
  }

  Future<void> refresh() async {
    state = state.copyWith(data: const AsyncValue.loading());
    try {
      final res = await _repository.getTodayAttendance();
      state = state.copyWith(data: AsyncValue.data(res));
    } catch (e, st) {
      state = state.copyWith(data: AsyncValue.error(e, st));
    }
  }

  Future<bool> submitEvent({
    required AttendanceEventType eventType,
    File? photoFile,
    String? notes,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final position = await LocationHelper.determinePosition();

      await _repository.submitAttendanceEvent(
        eventType: eventType,
        latitude: position.latitude,
        longitude: position.longitude,
        photoFile: photoFile,
        notes: notes,
      );

      await refresh();
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: e.toString(),
      );
      return false;
    }
  }
}

final todayAttendanceProvider =
    NotifierProvider<TodayAttendanceNotifier, TodayAttendanceState>(
        TodayAttendanceNotifier.new);
