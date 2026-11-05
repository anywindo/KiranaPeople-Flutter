import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bouncing_button.dart';
import '../../../../data/models/attendance_event_model.dart';
import '../../../../data/models/attendance_model.dart';
import '../../../../data/models/shift_model.dart';
import '../timing_column.dart';

class ShiftWorkPanel extends StatelessWidget {
  final Shift? selectedShift;
  final TodayAttendanceData? todayData;
  final bool hasStartedShift;
  final bool isCheckInLate;
  final bool hasEndedShift;
  final String? checkInTime;
  final String? checkOutTime;
  final AttendanceEvent? startShiftEvent;
  final AttendanceEvent? endShiftEvent;
  final VoidCallback onPickShift;

  const ShiftWorkPanel({
    super.key,
    required this.selectedShift,
    required this.todayData,
    required this.hasStartedShift,
    required this.isCheckInLate,
    required this.hasEndedShift,
    required this.checkInTime,
    required this.checkOutTime,
    required this.startShiftEvent,
    required this.endShiftEvent,
    required this.onPickShift,
  });

  String _formatShortTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '--:--';
    if (timeStr.length >= 5) {
      return timeStr.substring(0, 5);
    }
    return timeStr;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shift Row Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? const Color(0xFF0F172A)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.isDarkMode
                  ? const Color(0xFF334155)
                  : const Color(0xFFCBD5E1),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              // Clock icon in circle
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      (hasStartedShift
                              ? (isCheckInLate
                                    ? AppColors.error
                                    : AppColors.success)
                              : AppColors.primary)
                          .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        (hasStartedShift
                                ? (isCheckInLate
                                      ? AppColors.error
                                      : AppColors.success)
                                : AppColors.primary)
                            .withValues(alpha: 0.20),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.access_time_filled_rounded,
                  color: hasStartedShift
                      ? (isCheckInLate ? AppColors.error : AppColors.success)
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
                      color: AppColors.primary.withValues(alpha: 0.10),
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
        const SizedBox(height: 16),

        // Stats Row
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
        ),
      ],
    );
  }
}
