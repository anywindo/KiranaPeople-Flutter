import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/attendance_event_model.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/shift_model.dart';
import '../../data/models/work_location_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter/services.dart';
import '../../core/security/device_security_service.dart';
import '../../core/utils/location_helper.dart';
import '../../core/widgets/auto_oriented_image.dart';
import '../../core/widgets/bouncing_button.dart';
import '../navigation/main_navigation_screen.dart';
import 'camera_selfie_view.dart';
import 'shift_picker_sheet.dart';

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

    // Pre-warm device integrity report, GPS location, and auto-refresh when screen is mounted
    Future.microtask(() {
      DeviceSecurityService().getReport();
      LocationHelper.warmupPosition();
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
      // App resumed from background/lockscreen -> subtle background sync
      if (mounted && ref.read(authProvider).isAuthenticated) {
        ref.read(todayAttendanceProvider.notifier).refresh(isBackground: true);
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) {
      return 'Selamat Pagi,';
    } else if (hour < 15) {
      return 'Selamat Siang,';
    } else if (hour < 18) {
      return 'Selamat Sore,';
    } else {
      return 'Selamat Malam,';
    }
  }

  String _formatIndoDate(DateTime date) {
    const days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final dayName = days[date.weekday % 7];
    final monthName = months[date.month - 1];
    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  String _formatIndoFullDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  String _formatShortTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '--:--';
    if (timeStr.length >= 5) {
      return timeStr.substring(0, 5);
    }
    return timeStr;
  }

  bool _isTimeLate(String? actualTime, String? scheduledTime) {
    if (actualTime == null || scheduledTime == null) return false;
    try {
      final actualParts = actualTime.split(':');
      final schedParts = scheduledTime.split(':');
      final actualMin = int.parse(actualParts[0]) * 60 + int.parse(actualParts[1]);
      final schedMin = int.parse(schedParts[0]) * 60 + int.parse(schedParts[1]);
      return actualMin > schedMin;
    } catch (_) {
      return false;
    }
  }

  IconData _getEventIcon(AttendanceEventType type) {
    switch (type) {
      case AttendanceEventType.startShift:
        return Icons.work_rounded;
      case AttendanceEventType.startBreak:
        return Icons.coffee_rounded;
      case AttendanceEventType.endBreak:
        return Icons.business_center_rounded;
      case AttendanceEventType.endShift:
        return Icons.home_rounded;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF8E8E93))),
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
              Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
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

    final hasStartShift = events.any((e) => e.eventType == AttendanceEventType.startShift);
    final hasStartBreak = events.any((e) => e.eventType == AttendanceEventType.startBreak);
    final hasEndBreak = events.any((e) => e.eventType == AttendanceEventType.endBreak);
    final hasEndShift = events.any((e) => e.eventType == AttendanceEventType.endShift);

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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final attendanceState = ref.watch(todayAttendanceProvider);

    ref.listen<TodayAttendanceState>(todayAttendanceProvider, (previous, next) {
      if (next.submitError != null && previous?.submitError != next.submitError) {
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
    });

    final user = authState.user;

    final todayData = attendanceState.data.value;
    final selectedShift = attendanceState.selectedShift ??
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
    final hasEndedShift = endShiftEvent != null ||
        todayData?.status?.toUpperCase() == 'COMPLETED' ||
        todayData?.status?.toUpperCase() == 'SELESAI';
    final hasStartedBreak = startBreakEvent != null;
    final hasEndedBreak = endBreakEvent != null;
    final isOnBreak = hasStartedBreak && !hasEndedBreak;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(todayAttendanceProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Subtle background sync indicator (2px, zero layout shift)
                AnimatedOpacity(
                  opacity: attendanceState.isBackgroundSyncing ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(1),
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // 1. Top Header Bar (KIRANA GROUP + Logout)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'KIRANA GROUP',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    InkWell(
                      onTap: _showLogoutDialog,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: context.isDarkMode ? 0.2 : 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. User Greeting Row
                Row(
                  children: [
                    // Avatar photo or initials
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4338CA),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.isDarkMode ? context.surfaceColor : Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.3 : 0.10),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: user?.avatar != null && user!.avatar!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: user.avatar!,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => _buildUserInitial(user.name),
                              )
                            : _buildUserInitial(user?.name ?? 'User'),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Greeting + Name
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textMutedColor,
                          ),
                        ),
                        Text(
                          user?.name ?? 'User',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Segmented Switcher (Kerja / Istirahat) with Spring Slide Animation (Clamped/No Overflow)
                Container(
                  height: 48,
                  clipBehavior: Clip.antiAlias,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.surfaceSecondaryColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    clipBehavior: Clip.antiAlias,
                    children: [
                      // Smooth Spring Capsule Pill
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        alignment: _activeSegment == 0
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: FractionallySizedBox(
                          widthFactor: 0.5,
                          heightFactor: 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Touch Targets & Labels
                      Row(
                        children: [
                          // Kerja Tab
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (_activeSegment != 0) {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _activeSegment = 0;
                                  });
                                }
                              },
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.work_rounded,
                                      size: 16,
                                      color: _activeSegment == 0
                                          ? Colors.white
                                          : context.textSecondaryColor,
                                    ),
                                    const SizedBox(width: 6),
                                    AnimatedDefaultTextStyle(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: _activeSegment == 0
                                            ? Colors.white
                                            : context.textSecondaryColor,
                                      ),
                                      child: const Text('Kerja'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Istirahat Tab
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (_activeSegment != 1) {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _activeSegment = 1;
                                  });
                                }
                              },
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.coffee_rounded,
                                      size: 16,
                                      color: _activeSegment == 1
                                          ? Colors.white
                                          : context.textSecondaryColor,
                                    ),
                                    const SizedBox(width: 6),
                                    AnimatedDefaultTextStyle(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: _activeSegment == 1
                                            ? Colors.white
                                            : context.textSecondaryColor,
                                      ),
                                      child: const Text('Istirahat'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Shift & Attendance Action Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: context.isDarkMode ? 0.25 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtitle: Hari Ini (Sen, 19 Okt 2026) + Background sync status badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Hari Ini (${_formatIndoDate(DateTime.now())})',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8E8E93),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (attendanceState.isSubmitting)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Menyinkronkan...',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 1. Shift Row Box (Kerja) or Break Schedule Row (Istirahat) & Stats Row with Smooth Crossfade/Slide Animation
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.03),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey<int>(_activeSegment),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_activeSegment == 0) ...[
                                // Kerja: Shift Row Box
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: context.surfaceSecondaryColor,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: context.borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      // Clock icon in circle
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: (hasStartedShift
                                                  ? AppColors.success
                                                  : AppColors.primary)
                                              .withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.access_time_filled_rounded,
                                          color: hasStartedShift
                                              ? AppColors.success
                                              : AppColors.primary,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Shift title
                                      Expanded(
                                        child: Text(
                                          selectedShift != null
                                              ? '${selectedShift.name} (${_formatShortTime(selectedShift.startTime)} - ${_formatShortTime(selectedShift.endTime)})'
                                              : 'Pilih Shift Kerja',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: context.textPrimaryColor,
                                          ),
                                        ),
                                      ),

                                      // Pilih > Button (only before check-in)
                                      if (!hasStartedShift &&
                                          todayData?.availableShifts
                                                  ?.isNotEmpty ==
                                              true)
                                        BouncingButton(
                                          scaleDown: 0.90,
                                          onPressed: () {
                                            ShiftPickerSheet.show(
                                              context,
                                              shifts:
                                                  todayData!.availableShifts!,
                                              selectedShift: selectedShift,
                                              onShiftSelected: (s) {
                                                ref
                                                    .read(
                                                        todayAttendanceProvider
                                                            .notifier)
                                                    .selectShift(s);
                                              },
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.10),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Pilih',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                                SizedBox(width: 2),
                                                Icon(
                                                  Icons.chevron_right_rounded,
                                                  size: 16,
                                                  color: AppColors.primary,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                // Istirahat: Break Schedule Row
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: context.surfaceSecondaryColor,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: context.borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.coffee_rounded,
                                          color: AppColors.primary,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          selectedShift != null
                                              ? 'Jam Istirahat: [${selectedShift.effectiveBreakStart} - ${selectedShift.effectiveBreakEnd}]'
                                              : 'Jam Istirahat: [12:00 - 13:00]',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: context.textPrimaryColor,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: !hasStartedBreak
                                              ? (Shift.isBeforeBreakTime(selectedShift)
                                                  ? const Color(0xFFF3F4F6)
                                                  : AppColors.primary
                                                      .withValues(alpha: 0.10))
                                              : (!hasEndedBreak
                                                  ? AppColors.success
                                                      .withValues(alpha: 0.12)
                                                  : context.surfaceColor),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          !hasStartedBreak
                                              ? (Shift.isBeforeBreakTime(selectedShift)
                                                  ? 'Belum Waktunya'
                                                  : 'Belum Mulai')
                                              : (!hasEndedBreak
                                                  ? 'Sedang Istirahat'
                                                  : 'Selesai'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: !hasStartedBreak
                                                ? (Shift.isBeforeBreakTime(selectedShift)
                                                    ? const Color(0xFF6B7280)
                                                    : AppColors.primary)
                                                : (!hasEndedBreak
                                                    ? AppColors.success
                                                    : context.textSecondaryColor),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),

                              // 2. Stats Row: (Jam Masuk / Jam Pulang) vs (Mulai Istirahat / Selesai Istirahat)
                              if (_activeSegment == 0)
                                Row(
                                  children: [
                                    _buildTimingColumn(
                                      label: 'Jam Masuk',
                                      scheduledTime: _formatShortTime(
                                          selectedShift?.startTime ?? '08:00'),
                                      actualTime: checkInTime,
                                      event: startShiftEvent,
                                      fallbackIcon: Icons.work_rounded,
                                      isCompleted: hasStartedShift,
                                      isLate: _isTimeLate(
                                          checkInTime,
                                          selectedShift?.startTime ??
                                              '08:00'),
                                    ),
                                    const SizedBox(width: 12),
                                    _buildTimingColumn(
                                      label: 'Jam Pulang',
                                      scheduledTime: _formatShortTime(
                                          selectedShift?.endTime ?? '16:00'),
                                      actualTime: checkOutTime,
                                      event: endShiftEvent,
                                      fallbackIcon: Icons.home_rounded,
                                      isCompleted: hasEndedShift,
                                      isLate: false,
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    _buildTimingColumn(
                                      label: 'Mulai Istirahat',
                                      scheduledTime:
                                          selectedShift?.effectiveBreakStart ??
                                              '12:00',
                                      actualTime: startBreakTime,
                                      event: startBreakEvent,
                                      fallbackIcon: Icons.coffee_rounded,
                                      isCompleted: hasStartedBreak,
                                      isLate: false,
                                    ),
                                    const SizedBox(width: 12),
                                    _buildTimingColumn(
                                      label: 'Selesai Istirahat',
                                      scheduledTime:
                                          selectedShift?.effectiveBreakEnd ??
                                              '13:00',
                                      actualTime: endBreakTime,
                                      event: endBreakEvent,
                                      fallbackIcon:
                                          Icons.business_center_rounded,
                                      isCompleted: hasEndedBreak,
                                      isLate: false,
                                    ),
                                  ],
                                ),

                              // 3. Workflow Guidance Callout Banner
                              if (_activeSegment == 1 && !hasStartedShift) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF1F2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_rounded,
                                        color: AppColors.primary,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Presensi Masuk Kerja belum dilakukan. Silakan masuk kerja terlebih dahulu.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w500,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            _activeSegment = 0;
                                          });
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 2),
                                          child: Text(
                                            'Masuk',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                               ] else if (_activeSegment == 1 &&
                                  hasStartedShift &&
                                  !hasStartedBreak &&
                                  Shift.isBeforeBreakTime(selectedShift)) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: const Color(0xFFFDE68A)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time_rounded,
                                        color: Color(0xFFD97706),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Belum waktunya istirahat. Jadwal istirahat dimulai pukul ${selectedShift?.effectiveBreakStart ?? "12:00"}.',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFFB45309),
                                            fontWeight: FontWeight.w500,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            _activeSegment = 0;
                                          });
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 2),
                                          child: Text(
                                            'Ke Kerja',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFD97706),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else if (_activeSegment == 1 &&
                                  hasEndedBreak &&
                                  !hasEndedShift) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.success,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Istirahat selesai. Lakukan Pulang Kerja di tab Kerja saat shift berakhir.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w500,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            _activeSegment = 0;
                                          });
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 2),
                                          child: Text(
                                            'Ke Kerja',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Big Action Button
                      _buildMainActionButton(
                        isLoading: attendanceState.data.isLoading,
                        hasEndedShift: hasEndedShift,
                        hasStartedShift: hasStartedShift,
                        hasStartedBreak: hasStartedBreak,
                        hasEndedBreak: hasEndedBreak,
                        isOnBreak: isOnBreak,
                        targetAction: targetAction,
                        selectedShift: selectedShift,
                        workLocation: todayData?.workLocation,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Aktivitas Hari Ini Card (Matches Screenshot 2, 3, 4)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Aktivitas Hari Ini',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              MainNavigationScreen.of(context)?.switchToTab(2);
                            },
                            child: const Row(
                              children: [
                                Text(
                                  'Riwayat Lengkap',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Events or Empty placeholder
                      if (events.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: context.surfaceSecondaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.access_time_filled_rounded,
                                  color: Color(0xFFC7C7CC),
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Belum ada riwayat presensi hari ini.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: events.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 20,
                            thickness: 0.8,
                            color: context.dividerColor,
                          ),
                          itemBuilder: (context, index) {
                            // Sort newest first
                            final reversedList = events.reversed.toList();
                            final event = reversedList[index];
                            final dt = DateTime.tryParse(event.timestamp);
                            final localDt = dt != null ? (dt.isUtc ? dt.toLocal() : dt) : null;
                            final formattedTime = localDt != null
                                ? '${localDt.hour.toString().padLeft(2, '0')}:${localDt.minute.toString().padLeft(2, '0')}'
                                : event.timestamp;
                            final formattedDate = localDt != null
                                ? _formatIndoFullDate(localDt)
                                : 'Hari Ini';

                            return Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () => _showLocationDetail(
                                  event,
                                  todayData?.workLocation ?? user?.location,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 2),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // Circular Selfie or Fallback
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: context.borderColor,
                                              width: 1.5),
                                        ),
                                        child: ClipOval(
                                          child: (event.fullSelfieUrl != null &&
                                                  event.fullSelfieUrl!.isNotEmpty)
                                              ? AutoOrientedImage(
                                                  imageUrl: event.fullSelfieUrl!,
                                                  width: 44,
                                                  height: 44,
                                                  fit: BoxFit.cover,
                                                  errorWidget: Container(
                                                    color: AppColors.primary
                                                        .withValues(alpha: 0.12),
                                                    child: Icon(
                                                      _getEventIcon(
                                                          event.eventType),
                                                      color: AppColors.primary,
                                                      size: 20,
                                                    ),
                                                  ),
                                                )
                                              : Container(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.12),
                                                  child: Icon(
                                                    _getEventIcon(event.eventType),
                                                    color: AppColors.primary,
                                                    size: 20,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              event.eventType.label,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: context.textPrimaryColor,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Text(
                                                  formattedDate,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: context.textSecondaryColor,
                                                  ),
                                                ),
                                                if (event.latitude != null &&
                                                    event.longitude != null) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    width: 3,
                                                    height: 3,
                                                    decoration:
                                                        BoxDecoration(
                                                      color: context.borderColor,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  const Icon(
                                                    Icons.location_on_rounded,
                                                    size: 11,
                                                    color: Color(0xFF94A3B8),
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    'Lokasi GPS',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: context.textMutedColor,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            formattedTime,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: context.textPrimaryColor,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            size: 18,
                                            color: context.textMutedColor,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimingColumn({
    required String label,
    required String scheduledTime,
    required String? actualTime,
    required AttendanceEvent? event,
    required IconData fallbackIcon,
    required bool isCompleted,
    bool isLate = false,
  }) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular selfie avatar (tappable to view full photo)
          if (event?.fullSelfieUrl != null && event!.fullSelfieUrl!.isNotEmpty)
            GestureDetector(
              onTap: () => _showPhotoPreviewDialog(
                imageUrl: event.fullSelfieUrl!,
                title: 'Foto Presensi: $label',
                subtitle: actualTime != null ? 'Waktu: $actualTime' : null,
              ),
              child: Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFFE5E7EB), width: 1.5),
                    ),
                    child: ClipOval(
                      child: AutoOrientedImage(
                        imageUrl: event.fullSelfieUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          color: const Color(0xFFFFF1F2),
                          child: Icon(fallbackIcon,
                              color: AppColors.primary, size: 20),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        size: 9,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFE4E6), width: 1.5),
              ),
              child: Icon(
                fallbackIcon,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    text: label,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textSecondaryColor,
                      fontWeight: FontWeight.normal,
                    ),
                    children: [
                      TextSpan(
                        text: ' ($scheduledTime)',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actualTime ?? '--:--',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    if (isCompleted && actualTime != null) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.check_circle_rounded,
                        size: 15,
                        color: isLate
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoPreviewDialog({
    required String imageUrl,
    required String title,
    String? subtitle,
  }) {
    int rotationTurns = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Rotate Photo Button
                    InkWell(
                      onTap: () {
                        setDialogState(() {
                          rotationTurns = (rotationTurns + 1) % 4;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.rotate_right_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(20)),
                child: Container(
                  color: Colors.black,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.65,
                    minHeight: 250,
                    minWidth: double.infinity,
                  ),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: AutoOrientedImage(
                      imageUrl: imageUrl,
                      manualTurns: rotationTurns,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLocationDetail(AttendanceEvent event, [WorkLocation? workLocation]) {
    final lat = event.latitude ?? -7.025648;
    final lng = event.longitude ?? 109.957296;
    final userLatLng = LatLng(lat, lng);

    final resolvedWorkLocation = workLocation ??
        ref.read(todayAttendanceProvider).data.value?.workLocation ??
        ref.read(authProvider).user?.location;

    final officeLatLng = resolvedWorkLocation != null
        ? LatLng(resolvedWorkLocation.latitude, resolvedWorkLocation.longitude)
        : const LatLng(-7.025801, 109.956894);

    final officeName = (resolvedWorkLocation?.name != null &&
            resolvedWorkLocation!.name.isNotEmpty)
        ? resolvedWorkLocation.name
        : 'Kantor Utama (Tersono, Batang)';

    final radius = resolvedWorkLocation?.radius ?? 50.0;

    final distance = Geolocator.distanceBetween(
      userLatLng.latitude,
      userLatLng.longitude,
      officeLatLng.latitude,
      officeLatLng.longitude,
    );
    final isInside = distance <= radius;
    final hasPhoto =
        event.fullSelfieUrl != null && event.fullSelfieUrl!.isNotEmpty;
    int selectedTab = 0; // 0 = Map, 1 = Foto

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (hasPhoto)
                    GestureDetector(
                      onTap: () => _showPhotoPreviewDialog(
                        imageUrl: event.fullSelfieUrl!,
                        title: 'Foto Presensi: ${event.eventType.label}',
                        subtitle:
                            'Koordinat: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                      ),
                      child: Stack(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.primary, width: 2),
                            ),
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: event.fullSelfieUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => const Icon(
                                  Icons.person_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.search_rounded,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Titik Presensi: ${event.eventType.label}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Koordinat: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (hasPhoto) ...[
                const SizedBox(height: 14),
                Container(
                  height: 38,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: context.surfaceSecondaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => selectedTab = 0),
                          borderRadius: BorderRadius.circular(9),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selectedTab == 0
                                  ? context.surfaceColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: selectedTab == 0
                                  ? [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.06),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.map_rounded,
                                  size: 15,
                                  color: selectedTab == 0
                                      ? AppColors.primary
                                      : context.textSecondaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Peta Lokasi (2 Pin)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: selectedTab == 0
                                      ? AppColors.primary
                                      : context.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => selectedTab = 1),
                          borderRadius: BorderRadius.circular(9),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selectedTab == 1
                                  ? context.surfaceColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: selectedTab == 1
                                  ? [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.06),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt_rounded,
                                  size: 15,
                                  color: selectedTab == 1
                                      ? AppColors.primary
                                      : context.textSecondaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Foto Selfie',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: selectedTab == 1
                                      ? AppColors.primary
                                      : context.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              if (selectedTab == 1 && hasPhoto)
                GestureDetector(
                  onTap: () => _showPhotoPreviewDialog(
                    imageUrl: event.fullSelfieUrl!,
                    title: 'Foto Presensi: ${event.eventType.label}',
                    subtitle:
                        'Koordinat: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 220,
                          width: double.infinity,
                          color: const Color(0xFF0F172A),
                          child: AutoOrientedImage(
                            imageUrl: event.fullSelfieUrl!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fullscreen_rounded,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Perbesar Foto',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 220,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCameraFit: CameraFit.coordinates(
                          coordinates: [userLatLng, officeLatLng],
                          padding: const EdgeInsets.symmetric(
                              horizontal: 48, vertical: 48),
                          maxZoom: 17.0,
                        ),
                        initialCenter: userLatLng,
                        initialZoom: 16.5,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.kiranadesainindonesia.kiranapeople',
                        ),
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: officeLatLng,
                              radius: radius,
                              useRadiusInMeter: true,
                              color: AppColors.primary
                                  .withValues(alpha: 0.15),
                              borderColor: AppColors.primary,
                              borderStrokeWidth: 1.5,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            // 1. Office Pin (Kantor)
                            Marker(
                              point: officeLatLng,
                              width: 140,
                              height: 64,
                              alignment: Alignment.topCenter,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                            Icons.apartment_rounded,
                                            color: Colors.white,
                                            size: 10),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            officeName,
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.apartment_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 2. User Pin (Posisi User)
                            Marker(
                              point: userLatLng,
                              width: 120,
                              height: 64,
                              alignment: Alignment.topCenter,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF007AFF),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                            Icons.person_pin_circle_rounded,
                                            color: Colors.white,
                                            size: 11),
                                        SizedBox(width: 3),
                                        Text(
                                          'Posisi User',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF007AFF),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.person_pin_circle_rounded,
                                size: 16, color: Color(0xFF007AFF)),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Posisi User',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0369A1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: const Color(0xFFFECDD3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.apartment_rounded,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                officeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: context.surfaceSecondaryColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isInside
                            ? Icons.check_circle_rounded
                            : Icons.info_outline_rounded,
                        size: 15,
                        color: isInside
                            ? const Color(0xFF059669)
                            : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isInside
                              ? 'Dalam radius presensi (${distance.round()} m dari kantor)'
                              : 'Jarak ${distance >= 1000 ? '${(distance / 1000).toStringAsFixed(2)} km' : '${distance.round()} m'} dari titik kantor (Radius: ${radius.round()}m)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isInside
                                ? const Color(0xFF059669)
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainActionButton({
    required bool isLoading,
    required bool hasEndedShift,
    required bool hasStartedShift,
    required bool hasStartedBreak,
    required bool hasEndedBreak,
    required bool isOnBreak,
    required AttendanceEventType targetAction,
    required Shift? selectedShift,
    required dynamic workLocation,
  }) {
    if (isLoading) {
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Memeriksa Status Presensi...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (hasEndedShift) {
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 18),
              SizedBox(width: 8),
              Text(
                'Presensi Hari Ini Selesai',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        ),
      );
    }

    String label;
    IconData icon;

    if (_activeSegment == 1) {
      // Istirahat mode
      if (!hasStartedShift) {
        return Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Text(
              'Belum Masuk Kerja',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
        );
      }
      if (hasEndedBreak) {
        return Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Text(
              'Istirahat Selesai',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
        );
      }
      if (isOnBreak) {
        // Screenshot 3: User on break, ready to end break
        label = 'Selesai Istirahat';
        icon = Icons.sync_rounded;
      } else {
        if (Shift.isBeforeBreakTime(selectedShift)) {
          return InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Belum waktunya istirahat. Jadwal istirahat: ${selectedShift?.effectiveBreakStart ?? "12:00"} - ${selectedShift?.effectiveBreakEnd ?? "13:00"}',
                  ),
                  backgroundColor: const Color(0xFF4B5563),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  'Belum Waktunya Istirahat',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ),
          );
        }
        label = 'Mulai Istirahat';
        icon = Icons.coffee_rounded;
      }
    } else {
      // Kerja mode
      if (!hasStartedShift) {
        label = 'Masuk Kerja';
        icon = Icons.work_rounded;
      } else if (!hasStartedBreak) {
        // Screenshot 2: Checked in, but must take break first
        return Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Text(
              'Wajib Istirahat Dahulu',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
        );
      } else if (isOnBreak) {
        // Screenshot 4: User is on break, must complete break first
        return Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Text(
              'Selesaikan Istirahat Dahulu',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
        );
      } else {
        label = 'Pulang Kerja';
        icon = Icons.home_rounded;
      }
    }

    return BouncingButton(
      scaleDown: 0.96,
      onPressed: () async {
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
      },
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.40),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInitial(String name) {
    final trimmed = name.trim();
    String initial = 'US';
    if (trimmed.isNotEmpty) {
      final parts = trimmed.split(' ');
      if (parts.length >= 2) {
        initial = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initial =
            parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
      }
    }
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
