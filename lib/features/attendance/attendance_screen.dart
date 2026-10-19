import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/attendance_event_model.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/shift_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../navigation/main_navigation_screen.dart';
import 'camera_selfie_view.dart';
import 'shift_picker_sheet.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  // Mode: 0 = Kerja, 1 = Istirahat
  int _activeSegment = 0;

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
              Navigator.pop(ctx);
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
      backgroundColor: const Color(0xFFF6F7FA),
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
                // 1. Top Header Bar (KIRANA GROUP + Logout)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'KIRANA GROUP',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    InkWell(
                      onTap: _showLogoutDialog,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE5E5EA)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: Color(0xFF8E8E93),
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
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
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
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        Text(
                          user?.name ?? 'User',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Segmented Switcher (Kerja / Istirahat)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF1F5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      // Kerja Tab
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _activeSegment = 0;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _activeSegment == 0
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: _activeSegment == 0
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.work_rounded,
                                  size: 16,
                                  color: _activeSegment == 0
                                      ? Colors.white
                                      : const Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Kerja',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _activeSegment == 0
                                        ? Colors.white
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Istirahat Tab
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _activeSegment = 1;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _activeSegment == 1
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: _activeSegment == 1
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.coffee_rounded,
                                  size: 16,
                                  color: _activeSegment == 1
                                      ? Colors.white
                                      : const Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Istirahat',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _activeSegment == 1
                                        ? Colors.white
                                        : const Color(0xFF6B7280),
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
                const SizedBox(height: 16),

                // 4. Shift & Attendance Action Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF2F2F7)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtitle: Hari Ini (Sen, 19 Okt 2026)
                      Text(
                        'Hari Ini (${_formatIndoDate(DateTime.now())})',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8E8E93),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 1. Shift Row Box (Kerja) or Break Schedule Row (Istirahat)
                      if (_activeSegment == 0) ...[
                        // Kerja: Shift Row Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF2F2F7)),
                          ),
                          child: Row(
                            children: [
                              // Clock icon in circle
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (hasStartedShift ? AppColors.success : AppColors.primary)
                                      .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  hasStartedShift
                                      ? Icons.access_time_filled_rounded
                                      : Icons.access_time_filled_rounded,
                                  color: hasStartedShift ? AppColors.success : AppColors.primary,
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
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1C1C1E),
                                  ),
                                ),
                              ),

                              // Pilih > Button (only before check-in)
                              if (!hasStartedShift && todayData?.availableShifts?.isNotEmpty == true)
                                InkWell(
                                  onTap: () {
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
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(16),
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
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF2F2F7)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
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
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1C1C1E),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: !hasStartedBreak
                                      ? AppColors.primary.withValues(alpha: 0.10)
                                      : (!hasEndedBreak
                                          ? AppColors.success.withValues(alpha: 0.12)
                                          : const Color(0xFFF3F4F6)),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  !hasStartedBreak
                                      ? 'Belum Mulai'
                                      : (!hasEndedBreak
                                          ? 'Sedang Istirahat'
                                          : 'Selesai'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: !hasStartedBreak
                                        ? AppColors.primary
                                        : (!hasEndedBreak
                                            ? AppColors.success
                                            : const Color(0xFF4B5563)),
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
                              scheduledTime: _formatShortTime(selectedShift?.startTime ?? '08:00'),
                              actualTime: checkInTime,
                              event: startShiftEvent,
                              fallbackIcon: Icons.work_rounded,
                              isCompleted: hasStartedShift,
                              isLate: _isTimeLate(checkInTime, selectedShift?.startTime ?? '08:00'),
                            ),
                            const SizedBox(width: 12),
                            _buildTimingColumn(
                              label: 'Jam Pulang',
                              scheduledTime: _formatShortTime(selectedShift?.endTime ?? '16:00'),
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
                              scheduledTime: selectedShift?.effectiveBreakStart ?? '12:00',
                              actualTime: startBreakTime,
                              event: startBreakEvent,
                              fallbackIcon: Icons.coffee_rounded,
                              isCompleted: hasStartedBreak,
                              isLate: false,
                            ),
                            const SizedBox(width: 12),
                            _buildTimingColumn(
                              label: 'Selesai Istirahat',
                              scheduledTime: selectedShift?.effectiveBreakEnd ?? '13:00',
                              actualTime: endBreakTime,
                              event: endBreakEvent,
                              fallbackIcon: Icons.business_center_rounded,
                              isCompleted: hasEndedBreak,
                              isLate: false,
                            ),
                          ],
                        ),

                      // 3. Workflow Guidance Callout Banner (Matching screenshot)
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
                      ] else if (_activeSegment == 1 && hasEndedBreak && !hasEndedShift) ...[
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF2F2F7)),
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
                          const Text(
                            'Aktivitas Hari Ini',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1C1E),
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
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF9FAFB),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.access_time_filled_rounded,
                                  color: Color(0xFFC7C7CC),
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Belum ada riwayat presensi hari ini.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF8E8E93),
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
                          separatorBuilder: (_, _) => const Divider(
                            height: 20,
                            thickness: 0.8,
                            color: Color(0xFFF2F2F7),
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

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Circular Selfie or Fallback
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: const Color(0xFFE5E7EB), width: 1.5),
                                  ),
                                  child: ClipOval(
                                    child: (event.fullSelfieUrl != null &&
                                            event.fullSelfieUrl!.isNotEmpty)
                                        ? CachedNetworkImage(
                                            imageUrl: event.fullSelfieUrl!,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(
                                              color: const Color(0xFFF3F4F6),
                                              child: const Center(
                                                child: SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            errorWidget: (context, url, error) =>
                                                Container(
                                              color: const Color(0xFFFFF1F2),
                                              child: Icon(
                                                _getEventIcon(event.eventType),
                                                color: AppColors.primary,
                                                size: 20,
                                              ),
                                            ),
                                          )
                                        : Container(
                                            color: const Color(0xFFFFF1F2),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.eventType.label,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF8E8E93),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      InkWell(
                                        onTap: () => _showLocationDetail(event),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF1F2),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.error_outline_rounded,
                                                size: 13,
                                                color: Color(0xFFE11D48),
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Titik Lokasi',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFE11D48),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  formattedTime,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ],
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
          // Circular selfie avatar or pink icon container
          if (event?.fullSelfieUrl != null && event!.fullSelfieUrl!.isNotEmpty)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: event.fullSelfieUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFFF3F4F6),
                    child: const Center(
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFFFFF1F2),
                    child: Icon(fallbackIcon, color: AppColors.primary, size: 20),
                  ),
                ),
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
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
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

  void _showLocationDetail(AttendanceEvent event) {
    final lat = event.latitude ?? -6.9897;
    final lng = event.longitude ?? 109.8765;
    final latLng = LatLng(lat, lng);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Koordinat: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 200,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: latLng,
                    initialZoom: 16.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'com.kiranadesainindonesia.kiranapeople',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: latLng,
                          width: 44,
                          height: 44,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_pin_circle_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: AppColors.primary.withValues(alpha: 0.40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () async {
          final res = await CameraSelfieView.push(
            context,
            action: targetAction,
            shiftId: selectedShift?.id,
            workLocation: workLocation,
          );
          if (res == true) {
            ref.read(todayAttendanceProvider.notifier).refresh();
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
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
