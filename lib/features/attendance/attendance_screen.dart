import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/security/device_security_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/utils/location_helper.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../data/models/attendance_event_model.dart';
import '../../data/models/shift_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../navigation/main_navigation_screen.dart';
import 'camera_selfie_view.dart';
import 'shift_picker_sheet.dart';
import 'utils/attendance_event_resolver.dart';
import 'widgets/attendance_action_button.dart';
import 'widgets/attendance_error_dialog.dart';
import 'widgets/attendance_event_detail_modal.dart';
import 'widgets/attendance_header.dart';
import 'widgets/attendance_logout_dialog.dart';
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
  final ScrollController _scrollController = ScrollController();
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
    _scrollController.dispose();
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
    AttendanceLogoutDialog.show(
      context,
      onConfirmLogout: () => ref.read(authProvider.notifier).logout(),
    );
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
      AppHaptics.success();
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
        AttendanceErrorDialog.show(
          context,
          errorMessage: next.submitError!,
          onDismiss: () =>
              ref.read(todayAttendanceProvider.notifier).clearError(),
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

    final targetAction = AttendanceEventTimeline.resolveTargetAction(
      data: todayData,
      activeSegment: _activeSegment,
    );
    final timeline = AttendanceEventTimeline.fromData(
      data: todayData,
      selectedShift: selectedShift,
    );
    final events = todayData?.events ?? [];
    final isOffline = ref.watch(isOfflineProvider);

    if (todayData == null && attendanceState.data.isLoading) {
      return Scaffold(
        backgroundColor: context.scaffoldBg,
        body: const SafeArea(
          child: AttendanceScreenSkeleton(),
        ),
      );
    }

    final topPadding = isOffline ? 4.0 : MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Stack(
        children: [
          // 1. Scrollable Page Body (flows behind sticky top bar with blur gradient)
          RefreshIndicator(
            color: AppColors.primary,
            edgeOffset: topPadding + 48,
            onRefresh: () => ref.read(todayAttendanceProvider.notifier).refresh(),
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, topPadding + 54, 16, 128),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Greeting Section (tap redirects to Profile) & Small Live Clock
                  AttendanceGreetingSection(user: user),
                  const SizedBox(height: 12),

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
                  hasStartedShift: timeline.hasStartedShift,
                  isCheckInLate: timeline.isCheckInLate,
                  hasEndedShift: timeline.hasEndedShift,
                  hasStartedBreak: timeline.hasStartedBreak,
                  hasEndedBreak: timeline.hasEndedBreak,
                  checkInTime: timeline.checkInTime,
                  checkOutTime: timeline.checkOutTime,
                  startBreakTime: timeline.startBreakTime,
                  endBreakTime: timeline.endBreakTime,
                  startShiftEvent: timeline.startShiftEvent,
                  endShiftEvent: timeline.endShiftEvent,
                  startBreakEvent: timeline.startBreakEvent,
                  endBreakEvent: timeline.endBreakEvent,
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
                    hasEndedShift: timeline.hasEndedShift,
                    hasStartedShift: timeline.hasStartedShift,
                    hasStartedBreak: timeline.hasStartedBreak,
                    hasEndedBreak: timeline.hasEndedBreak,
                    isOnBreak: timeline.isOnBreak,
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

        // 2. Sticky Top Bar (KIRANA GROUP, Sync Indicator, Refresh & Logout buttons)
        // Pinned on top, zero background when resting, feathered blur gradient when scrolled
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AttendanceStickyTopBar(
            isBackgroundSyncing: attendanceState.isBackgroundSyncing,
            onRefresh: () {
              ref.read(todayAttendanceProvider.notifier).refresh();
            },
            onLogout: _showLogoutDialog,
            scrollController: _scrollController,
            topPadding: topPadding,
          ),
        ),
      ],
    ),
  );
  }
}
