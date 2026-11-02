import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bouncing_button.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/attendance_event_model.dart';
import '../../../data/models/shift_model.dart';
import 'timing_column.dart';

class ShiftInfoCard extends StatelessWidget {
  final int activeSegment; // 0 = Kerja, 1 = Istirahat
  final Shift? selectedShift;
  final TodayAttendanceData? todayData;
  final bool isSubmitting;
  final bool hasStartedShift;
  final bool isCheckInLate;
  final bool hasEndedShift;
  final bool hasStartedBreak;
  final bool hasEndedBreak;
  final String? checkInTime;
  final String? checkOutTime;
  final String? startBreakTime;
  final String? endBreakTime;
  final AttendanceEvent? startShiftEvent;
  final AttendanceEvent? endShiftEvent;
  final AttendanceEvent? startBreakEvent;
  final AttendanceEvent? endBreakEvent;
  final VoidCallback onPickShift;
  final VoidCallback onSwitchToWork;
  final Widget actionButton;

  const ShiftInfoCard({
    super.key,
    required this.activeSegment,
    required this.selectedShift,
    required this.todayData,
    required this.isSubmitting,
    required this.hasStartedShift,
    required this.isCheckInLate,
    required this.hasEndedShift,
    required this.hasStartedBreak,
    required this.hasEndedBreak,
    required this.checkInTime,
    required this.checkOutTime,
    required this.startBreakTime,
    required this.endBreakTime,
    required this.startShiftEvent,
    required this.endShiftEvent,
    required this.startBreakEvent,
    required this.endBreakEvent,
    required this.onPickShift,
    required this.onSwitchToWork,
    required this.actionButton,
  });

  String _formatIndoDate(DateTime date) {
    const days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final dayName = days[date.weekday % 7];
    final monthName = months[date.month - 1];
    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  String _formatShortTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '--:--';
    if (timeStr.length >= 5) {
      return timeStr.substring(0, 5);
    }
    return timeStr;
  }

  bool _isBreakTimeLate(
    String? actualTime,
    String? breakStartTime,
    String? breakEndTime,
  ) {
    if (actualTime == null || breakStartTime == null || breakEndTime == null) {
      return false;
    }
    try {
      final actualParts = actualTime.split(':');
      final startParts = breakStartTime.split(':');
      final endParts = breakEndTime.split(':');
      final actualMin =
          int.parse(actualParts[0]) * 60 + int.parse(actualParts[1]);
      final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      if (endMin >= startMin) {
        return actualMin < startMin || actualMin > endMin;
      } else {
        return actualMin < startMin && actualMin > endMin;
      }
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.25 : 0.03,
            ),
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
              if (isSubmitting)
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

          // Shift Row Box or Break Schedule Row with Smooth Crossfade/Slide Animation
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
              key: ValueKey<int>(activeSegment),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activeSegment == 0) ...[
                    // Kerja: Shift Row Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.surfaceSecondaryColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Row(
                        children: [
                          // Clock icon in circle
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (hasStartedShift
                                      ? (isCheckInLate
                                          ? AppColors.error
                                          : AppColors.success)
                                      : AppColors.primary)
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.access_time_filled_rounded,
                              color: hasStartedShift
                                  ? (isCheckInLate
                                      ? AppColors.error
                                      : AppColors.success)
                                  : AppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Shift title
                          Expanded(
                            child: Text(
                              selectedShift != null
                                  ? '${selectedShift!.name} (${_formatShortTime(selectedShift!.startTime)} - ${_formatShortTime(selectedShift!.endTime)})'
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
                              todayData?.availableShifts?.isNotEmpty == true)
                            BouncingButton(
                              scaleDown: 0.90,
                              onPressed: onPickShift,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.10,
                                  ),
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
                        color: context.surfaceSecondaryColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.borderColor),
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
                                  ? 'Jam Istirahat: [${selectedShift!.effectiveBreakStart} - ${selectedShift!.effectiveBreakEnd}]'
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
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: !hasStartedBreak
                                  ? (Shift.isBeforeBreakTime(selectedShift)
                                      ? const Color(0xFFF3F4F6)
                                      : AppColors.primary.withValues(
                                          alpha: 0.10,
                                        ))
                                  : (!hasEndedBreak
                                      ? AppColors.success.withValues(
                                          alpha: 0.12,
                                        )
                                      : context.surfaceColor),
                              borderRadius: BorderRadius.circular(20),
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

                  // Stats Row
                  if (activeSegment == 0)
                    Row(
                      children: [
                        TimingColumn(
                          label: 'Jam Masuk',
                          scheduledTime: _formatShortTime(
                            selectedShift?.startTime ?? '08:00',
                          ),
                          actualTime: checkInTime,
                          event: startShiftEvent,
                          fallbackIcon: Icons.work_rounded,
                          isCompleted: hasStartedShift,
                          isLate: isCheckInLate,
                        ),
                        const SizedBox(width: 12),
                        TimingColumn(
                          label: 'Jam Pulang',
                          scheduledTime: _formatShortTime(
                            selectedShift?.endTime ?? '16:00',
                          ),
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
                        TimingColumn(
                          label: 'Mulai Istirahat',
                          scheduledTime:
                              selectedShift?.effectiveBreakStart ?? '12:00',
                          actualTime: startBreakTime,
                          event: startBreakEvent,
                          fallbackIcon: Icons.coffee_rounded,
                          isCompleted: hasStartedBreak,
                          isLate: _isBreakTimeLate(
                            startBreakTime,
                            selectedShift?.effectiveBreakStart ?? '12:00',
                            selectedShift?.effectiveBreakEnd ?? '13:00',
                          ),
                        ),
                        const SizedBox(width: 12),
                        TimingColumn(
                          label: 'Selesai Istirahat',
                          scheduledTime:
                              selectedShift?.effectiveBreakEnd ?? '13:00',
                          actualTime: endBreakTime,
                          event: endBreakEvent,
                          fallbackIcon: Icons.business_center_rounded,
                          isCompleted: hasEndedBreak,
                          isLate: _isBreakTimeLate(
                            endBreakTime,
                            selectedShift?.effectiveBreakStart ?? '12:00',
                            selectedShift?.effectiveBreakEnd ?? '13:00',
                          ),
                        ),
                      ],
                    ),

                  // Workflow Guidance Callout Banner
                  if (activeSegment == 1 && !hasStartedShift) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
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
                            onTap: onSwitchToWork,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
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
                  ] else if (activeSegment == 1 &&
                      hasStartedShift &&
                      !hasStartedBreak &&
                      Shift.isBeforeBreakTime(selectedShift)) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFDE68A)),
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
                            onTap: onSwitchToWork,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
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
                  ] else if (activeSegment == 1 &&
                      hasEndedBreak &&
                      !hasEndedShift) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
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
                            onTap: onSwitchToWork,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
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
          actionButton,
        ],
      ),
    );
  }
}
