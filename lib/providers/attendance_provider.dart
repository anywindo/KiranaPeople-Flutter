import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/shift_model.dart';
import '../data/models/attendance_model.dart';
import '../data/models/attendance_event_model.dart';
import '../data/repositories/attendance_repository.dart';
import 'auth_provider.dart';
import 'history_provider.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

class TodayAttendanceState {
  final AsyncValue<TodayAttendanceData> data;
  final Shift? selectedShift;
  final bool isSubmitting;
  final String? submitError;

  const TodayAttendanceState({
    this.data = const AsyncValue.loading(),
    this.selectedShift,
    this.isSubmitting = false,
    this.submitError,
  });

  TodayAttendanceState copyWith({
    AsyncValue<TodayAttendanceData>? data,
    Shift? selectedShift,
    bool? isSubmitting,
    String? submitError,
    bool clearError = false,
  }) {
    return TodayAttendanceState(
      data: data ?? this.data,
      selectedShift: selectedShift ?? this.selectedShift,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearError ? null : (submitError ?? this.submitError),
    );
  }
}

class TodayAttendanceNotifier extends Notifier<TodayAttendanceState> {
  AttendanceRepository get _repository => ref.read(attendanceRepositoryProvider);

  @override
  TodayAttendanceState build() {
    // Watch authProvider: when auth changes, build() automatically updates cleanly
    final authState = ref.watch(authProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      return const TodayAttendanceState();
    }

    Future.microtask(() => refresh());
    return const TodayAttendanceState();
  }

  void reset() {
    state = const TodayAttendanceState();
  }

  Future<void> refresh() async {
    // Prevent fetching or retaining state when not authenticated
    if (!ref.read(authProvider).isAuthenticated) {
      state = const TodayAttendanceState();
      return;
    }

    state = state.copyWith(data: const AsyncValue.loading());
    try {
      final res = await _repository.getTodayAttendance();
      final initialShift = state.selectedShift ??
          res.shift ??
          (res.availableShifts?.isNotEmpty == true ? res.availableShifts!.first : null);
      state = state.copyWith(
        data: AsyncValue.data(res),
        selectedShift: initialShift,
      );
    } catch (e, st) {
      state = state.copyWith(data: AsyncValue.error(e, st));
    }
  }

  void selectShift(Shift shift) {
    state = state.copyWith(selectedShift: shift);
  }

  Future<bool> submitEvent({
    required AttendanceEventType eventType,
    required double latitude,
    required double longitude,
    File? photoFile,
    int? shiftId,
    String? notes,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repository.submitAttendanceEvent(
        eventType: eventType,
        latitude: latitude,
        longitude: longitude,
        photoFile: photoFile,
        shiftId: shiftId ?? state.selectedShift?.id,
        notes: notes,
      );

      await refresh();
      // Auto-refresh history so newly submitted attendance event appears instantly
      ref.read(historyProvider.notifier).refresh();
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

final todayAttendanceProvider =
    NotifierProvider<TodayAttendanceNotifier, TodayAttendanceState>(
        TodayAttendanceNotifier.new);
