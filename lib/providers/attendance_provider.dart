import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/shift_model.dart';
import '../data/models/attendance_model.dart';
import '../data/models/attendance_event_model.dart';
import '../data/repositories/attendance_repository.dart';
import '../core/network/api_exception.dart';
import 'auth_provider.dart';
import 'history_provider.dart';

class TodayAttendanceState {
  final AsyncValue<TodayAttendanceData> data;
  final Shift? selectedShift;
  final bool isSubmitting;
  final String? submitError;
  final bool isBackgroundSyncing;

  const TodayAttendanceState({
    this.data = const AsyncValue.loading(),
    this.selectedShift,
    this.isSubmitting = false,
    this.submitError,
    this.isBackgroundSyncing = false,
  });

  TodayAttendanceState copyWith({
    AsyncValue<TodayAttendanceData>? data,
    Shift? selectedShift,
    bool? isSubmitting,
    String? submitError,
    bool clearError = false,
    bool? isBackgroundSyncing,
  }) {
    return TodayAttendanceState(
      data: data ?? this.data,
      selectedShift: selectedShift ?? this.selectedShift,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearError ? null : (submitError ?? this.submitError),
      isBackgroundSyncing: isBackgroundSyncing ?? this.isBackgroundSyncing,
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

  Future<void> refresh({bool isBackground = false}) async {
    // Prevent fetching or retaining state when not authenticated
    if (!ref.read(authProvider).isAuthenticated) {
      state = const TodayAttendanceState();
      return;
    }

    final hasExistingData = state.data.hasValue;
    if (hasExistingData || isBackground) {
      // Subtle background sync: do not wipe existing data
      state = state.copyWith(isBackgroundSyncing: true);
    } else {
      state = state.copyWith(data: const AsyncValue.loading());
    }

    try {
      final res = await _repository.getTodayAttendance();
      final initialShift = state.selectedShift ??
          res.shift ??
          (res.availableShifts?.isNotEmpty == true ? res.availableShifts!.first : null);
      state = state.copyWith(
        data: AsyncValue.data(res),
        selectedShift: initialShift,
        isBackgroundSyncing: false,
      );
    } catch (e, st) {
      // If we already have data, preserve it silently and just clear syncing flag
      if (hasExistingData) {
        state = state.copyWith(isBackgroundSyncing: false);
      } else {
        state = state.copyWith(
          data: AsyncValue.error(e, st),
          isBackgroundSyncing: false,
        );
      }
    }
  }

  void selectShift(Shift shift) {
    state = state.copyWith(selectedShift: shift);
  }

  Future<bool> submitEvent({
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
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repository.submitAttendanceEvent(
        eventType: eventType,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        altitude: altitude,
        deviceTimestamp: deviceTimestamp,
        isMocked: isMocked,
        isDeviceRooted: isDeviceRooted,
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
      // Reconcile timeout or connection error:
      // If the server received and processed the request before the client connection was aborted,
      // or if the event was already registered, verify if today's attendance actually contains the submitted event.
      final errorMessage = e.toString().toLowerCase();
      final isTimeoutOrNetworkError = e is ApiException &&
          (e.message.contains('waktu habis') ||
              e.message.contains('koneksi') ||
              e.message.contains('terputus') ||
              e.statusCode == null ||
              e.statusCode == 504);

      final isAlreadyRecordedError = errorMessage.contains('sudah dilakukan') ||
          errorMessage.contains('sudah dimulai') ||
          errorMessage.contains('sudah dicatat');

      if (isTimeoutOrNetworkError || isAlreadyRecordedError) {
        try {
          final res = await _repository.getTodayAttendance();
          final hasEventRecorded = res.events?.any(
                (event) => event.eventType == eventType,
              ) ??
              false;

          if (hasEventRecorded) {
            final initialShift = state.selectedShift ??
                res.shift ??
                (res.availableShifts?.isNotEmpty == true
                    ? res.availableShifts!.first
                    : null);
            state = state.copyWith(
              data: AsyncValue.data(res),
              selectedShift: initialShift,
              isSubmitting: false,
              clearError: true,
            );
            ref.read(historyProvider.notifier).refresh();
            return true;
          }
        } catch (_) {
          // If server check fails, proceed to standard error state
        }
      }

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
