import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/security/device_security_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/location_helper.dart';
// import '../../core/widgets/offline_banner.dart';
import '../../data/models/attendance_event_model.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/shift_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../navigation/main_navigation_screen.dart';
import 'camera_selfie_view.dart';
import 'shift_picker_sheet.dart';
import 'widgets/attendance_action_button.dart';
import 'widgets/attendance_event_detail_modal.dart';
import 'widgets/attendance_header.dart';
import 'widgets/attendance_mode_switcher.dart';
import 'widgets/shift_info_card.dart';
import 'widgets/today_activity_card.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen>
    with WidgetsBindingObserver {
  // Mode: 0 = Kerja, 1 = Istirahat
  int _activeSegment = 0;
  Timer? _autoRefreshTimer;
  Timer? _minuteTicker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Pre-warm device integrity report, GPS location, request notification permissions, and auto-refresh when screen is mounted
    Future.microtask(() {
      DeviceSecurityService().getReport();
      LocationHelper.warmupPosition();
      NotificationService.instance.requestPermissions();
      if (mounted && ref.read(authProvider).isAuthenticated) {
        ref.read(todayAttendanceProvider.notifier).refresh();
      }
    });

    // Auto-refresh periodically every 60 seconds (subtle background sync)
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted && ref.read(authProvider).isAuthenticated) {
        ref.read(todayAttendanceProvider.notifier).refresh(isBackground: true);
      }
    });

    // Minute ticker to dynamically update time-based button states (e.g. break availability)
    _minuteTicker = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    _minuteTicker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted && ref.read(authProvider).isAuthenticated) {
        ref.read(todayAttendanceProvider.notifier).refresh(isBackground: true);
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Keluar Akun',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF8E8E93)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(
                context,
                rootNavigator: true,
              ).popUntil((route) => route.isFirst);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  AttendanceEventType _resolveTargetAction(TodayAttendanceData? data) {
    final nextAllowed = data?.nextAllowedAction;
    if (nextAllowed != null && nextAllowed.isNotEmpty) {
      return AttendanceEventType.fromString(nextAllowed);
    }

    final events = data?.events ?? [];
    if (events.isEmpty) return AttendanceEventType.startShift;

    final hasStartShift = events.any(
      (e) => e.eventType == AttendanceEventType.startShift,
    );
    final hasStartBreak = events.any(
      (e) => e.eventType == AttendanceEventType.startBreak,
    );
    final hasEndBreak = events.any(
      (e) => e.eventType == AttendanceEventType.endBreak,
    );
    final hasEndShift = events.any(
      (e) => e.eventType == AttendanceEventType.endShift,
    );

    if (hasEndShift) return AttendanceEventType.startShift;

    if (_activeSegment == 1) {
      // Istirahat Mode
      if (hasStartBreak && !hasEndBreak) {
        return AttendanceEventType.endBreak;
      }
      return AttendanceEventType.startBreak;
    } else {
      // Kerja Mode
      if (!hasStartShift) {
        return AttendanceEventType.startShift;
      }
      return AttendanceEventType.endShift;
    }
  }

  Future<void> _handleActionPress({
    required AttendanceEventType targetAction,
    required Shift? selectedShift,
    required dynamic workLocation,
  }) async {
    final availableShifts =
        ref.read(todayAttendanceProvider).data.value?.availableShifts;
    if (targetAction == AttendanceEventType.startShift &&
        selectedShift == null &&
        availableShifts?.isNotEmpty == true) {
      ShiftPickerSheet.show(
        context,
        shifts: availableShifts!,
        selectedShift: selectedShift,
        onShiftSelected: (s) {
          ref.read(todayAttendanceProvider.notifier).selectShift(s);
        },
      );
      return;
    }

    final res = await CameraSelfieView.push(
      context,
      action: targetAction,
      shiftId: selectedShift?.id,
      workLocation: workLocation,
    );
    if (res == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${targetAction.label} berhasil dicatat!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final attendanceState = ref.watch(todayAttendanceProvider);

    ref.listen<TodayAttendanceState>(todayAttendanceProvider, (previous, next) {
      if (next.submitError != null &&
          previous?.submitError != next.submitError) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Presensi Belum Tersimpan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(next.submitError!),
            actions: [
              TextButton(
                onPressed: () {
                  ref.read(todayAttendanceProvider.notifier).clearError();
                  Navigator.pop(ctx);
                },
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
      }

      // Automatically sync scheduled attendance reminders when data loads or updates
      final nextData = next.data.value;
      if (nextData != null) {
        final shift = next.selectedShift ??
            nextData.shift ??
            (nextData.availableShifts?.isNotEmpty == true
                ? nextData.availableShifts!.first
                : null);
        NotificationService.instance.scheduleAttendanceReminders(
          shift: shift,
          events: nextData.events ?? [],
        );
      }
    });

    final user = authState.user;
    final todayData = attendanceState.data.value;
    final selectedShift =
        attendanceState.selectedShift ??
        todayData?.shift ??
        (todayData?.availableShifts?.isNotEmpty == true
            ? todayData!.availableShifts!.first
            : null);

    final targetAction = _resolveTargetAction(todayData);
    final events = todayData?.events ?? [];

    // Find actual event times
    String? checkInTime;
    String? checkOutTime;
    String? startBreakTime;
    String? endBreakTime;

    AttendanceEvent? startShiftEvent;
    AttendanceEvent? endShiftEvent;
    AttendanceEvent? startBreakEvent;
    AttendanceEvent? endBreakEvent;

    for (final e in events) {
      final dt = DateTime.tryParse(e.timestamp);
      final localDt = dt != null ? (dt.isUtc ? dt.toLocal() : dt) : null;
      final formattedTime = localDt != null
          ? '${localDt.hour.toString().padLeft(2, '0')}:${localDt.minute.toString().padLeft(2, '0')}'
          : e.timestamp;

      if (e.eventType == AttendanceEventType.startShift) {
        startShiftEvent = e;
        checkInTime = formattedTime;
      } else if (e.eventType == AttendanceEventType.endShift) {
        endShiftEvent = e;
        checkOutTime = formattedTime;
      } else if (e.eventType == AttendanceEventType.startBreak) {
        startBreakEvent = e;
        startBreakTime = formattedTime;
      } else if (e.eventType == AttendanceEventType.endBreak) {
        endBreakEvent = e;
        endBreakTime = formattedTime;
      }
    }

    final hasStartedShift = startShiftEvent != null;
    final isCheckInLate = Shift.isShiftStartLate(
      actualTime: checkInTime,
      scheduledTime: selectedShift?.startTime ?? '08:00',
      ruleEnabled:
          selectedShift?.attendanceRuleEnabled ??
          todayData?.attendanceRuleEnabled ??
          true,
      ruleMinutes:
          selectedShift?.attendanceRuleMinutes ??
          todayData?.attendanceRuleMinutes ??
          15,
    );
    final hasEndedShift =
        endShiftEvent != null ||
        todayData?.status?.toUpperCase() == 'COMPLETED' ||
        todayData?.status?.toUpperCase() == 'SELESAI';
    final hasStartedBreak = startBreakEvent != null;
    final hasEndedBreak = endBreakEvent != null;
    final isBannerVisible = ref.watch(isBannerVisibleProvider);
    final isOnBreak = hasStartedBreak && !hasEndedBreak;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        top: !isBannerVisible,
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(todayAttendanceProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, isBannerVisible ? 4 : 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header (Kirana Group, Sync indicator, Refresh, Logout, User Greeting)
                AttendanceHeader(
                  user: user,
                  isBackgroundSyncing: attendanceState.isBackgroundSyncing,
                  onRefresh: () {
                    ref.read(todayAttendanceProvider.notifier).refresh();
                  },
                  onLogout: _showLogoutDialog,
                ),
                const SizedBox(height: 12),

                // Offline Status Indicator Card (commented out in favor of top OfflineBanner)
                // OfflineCardWarning(
                //   onRetry: () =>
                //       ref.read(isOfflineProvider.notifier).checkConnection(),
                // ),
                // const SizedBox(height: 4),

                // 2. Mode Switcher (Kerja / Istirahat)
                AttendanceModeSwitcher(
                  activeSegment: _activeSegment,
                  onSegmentChanged: (newSegment) {
                    setState(() {
                      _activeSegment = newSegment;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // 3. Shift Info & Action Card
                ShiftInfoCard(
                  activeSegment: _activeSegment,
                  selectedShift: selectedShift,
                  todayData: todayData,
                  isSubmitting: attendanceState.isSubmitting,
                  hasStartedShift: hasStartedShift,
                  isCheckInLate: isCheckInLate,
                  hasEndedShift: hasEndedShift,
                  hasStartedBreak: hasStartedBreak,
                  hasEndedBreak: hasEndedBreak,
                  checkInTime: checkInTime,
                  checkOutTime: checkOutTime,
                  startBreakTime: startBreakTime,
                  endBreakTime: endBreakTime,
                  startShiftEvent: startShiftEvent,
                  endShiftEvent: endShiftEvent,
                  startBreakEvent: startBreakEvent,
                  endBreakEvent: endBreakEvent,
                  onPickShift: () {
                    if (todayData?.availableShifts?.isNotEmpty == true) {
                      ShiftPickerSheet.show(
                        context,
                        shifts: todayData!.availableShifts!,
                        selectedShift: selectedShift,
                        onShiftSelected: (s) {
                          ref
                              .read(todayAttendanceProvider.notifier)
                              .selectShift(s);
                        },
                      );
                    }
                  },
                  onSwitchToWork: () {
                    setState(() {
                      _activeSegment = 0;
                    });
                  },
                  actionButton: AttendanceActionButton(
                    isLoading: attendanceState.data.isLoading,
                    hasEndedShift: hasEndedShift,
                    hasStartedShift: hasStartedShift,
                    hasStartedBreak: hasStartedBreak,
                    hasEndedBreak: hasEndedBreak,
                    isOnBreak: isOnBreak,
                    activeSegment: _activeSegment,
                    selectedShift: selectedShift,
                    onAction: () => _handleActionPress(
                      targetAction: targetAction,
                      selectedShift: selectedShift,
                      workLocation: todayData?.workLocation,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Aktivitas Hari Ini Card
                TodayActivityCard(
                  events: events,
                  onViewFullHistory: () {
                    MainNavigationScreen.of(context)?.switchToTab(2);
                  },
                  onEventTap: (event) {
                    AttendanceEventDetailModal.show(
                      context,
                      event: event,
                      workLocation: todayData?.workLocation ?? user?.location,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
