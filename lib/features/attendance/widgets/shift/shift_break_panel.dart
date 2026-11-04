import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/attendance_event_model.dart';
import '../../../../data/models/shift_model.dart';
import '../timing_column.dart';

class ShiftBreakPanel extends StatelessWidget {
  final Shift? selectedShift;
  final bool hasStartedShift;
  final bool hasStartedBreak;
  final bool hasEndedBreak;
  final bool hasEndedShift;
  final String? startBreakTime;
  final String? endBreakTime;
  final AttendanceEvent? startBreakEvent;
  final AttendanceEvent? endBreakEvent;
  final VoidCallback onSwitchToWork;

  const ShiftBreakPanel({
    super.key,
    required this.selectedShift,
    required this.hasStartedShift,
    required this.hasStartedBreak,
    required this.hasEndedBreak,
    required this.hasEndedShift,
    required this.startBreakTime,
    required this.endBreakTime,
    required this.startBreakEvent,
    required this.endBreakEvent,
    required this.onSwitchToWork,
  });

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Break Schedule Row
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: context.isDarkMode
                  ? [
                      const Color(0xFF14161C),
                      const Color(0xFF1A1C24),
                    ]
                  : [
                      const Color(0xFFEFF2F6),
                      const Color(0xFFF8FAFC),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.isDarkMode
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFDDE3EA),
              width: 1.0,
            ),
            boxShadow: [
              // Inset feel with slight dark top/contact shadow
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: context.isDarkMode ? 0.25 : 0.035,
                ),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
              // Bottom specular bounce line
              BoxShadow(
                color: (context.isDarkMode
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.white)
                    .withValues(alpha: context.isDarkMode ? 0.05 : 0.8),
                blurRadius: 0,
                spreadRadius: 0.6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.20),
                      AppColors.primary.withValues(alpha: 0.08),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: context.isDarkMode ? 0.15 : 0.70,
                    ),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: context.isDarkMode ? 0.2 : 0.05,
                      ),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
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
                          : AppColors.primary.withValues(alpha: 0.10))
                      : (!hasEndedBreak
                          ? AppColors.success.withValues(alpha: 0.12)
                          : context.surfaceColor),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  !hasStartedBreak
                      ? (Shift.isBeforeBreakTime(selectedShift)
                          ? 'Belum Waktunya'
                          : 'Belum Mulai')
                      : (!hasEndedBreak ? 'Sedang Istirahat' : 'Selesai'),
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
        const SizedBox(height: 16),

        // Stats Row
        Row(
          children: [
            TimingColumn(
              label: 'Mulai Istirahat',
              scheduledTime: selectedShift?.effectiveBreakStart ?? '12:00',
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
              scheduledTime: selectedShift?.effectiveBreakEnd ?? '13:00',
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
        if (!hasStartedShift) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? const Color(0xFF4C0519).withValues(alpha: 0.5)
                  : const Color(0xFFFFF1F2),
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
        ] else if (hasStartedShift &&
            !hasStartedBreak &&
            Shift.isBeforeBreakTime(selectedShift)) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? const Color(0xFF451A03).withValues(alpha: 0.5)
                  : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: context.isDarkMode
                    ? const Color(0xFF78350F)
                    : const Color(0xFFFDE68A),
              ),
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
        ] else if (hasEndedBreak && !hasEndedShift) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? const Color(0xFF064E3B).withValues(alpha: 0.5)
                  : const Color(0xFFDCFCE7),
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
    );
  }
}

