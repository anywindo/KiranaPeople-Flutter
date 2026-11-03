import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/widgets/bouncing_button.dart';
import '../../../data/models/shift_model.dart';

class AttendanceActionButton extends StatelessWidget {
  final bool isLoading;
  final bool hasEndedShift;
  final bool hasStartedShift;
  final bool hasStartedBreak;
  final bool hasEndedBreak;
  final bool isOnBreak;
  final int activeSegment; // 0 = Kerja, 1 = Istirahat
  final Shift? selectedShift;
  final VoidCallback onAction;

  const AttendanceActionButton({
    super.key,
    required this.isLoading,
    required this.hasEndedShift,
    required this.hasStartedShift,
    required this.hasStartedBreak,
    required this.hasEndedBreak,
    required this.isOnBreak,
    required this.activeSegment,
    required this.selectedShift,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
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
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 18,
              ),
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

    if (activeSegment == 1) {
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
        label = 'Selesai Istirahat';
        icon = Icons.sync_rounded;
      } else {
        if (Shift.isBeforeBreakTime(selectedShift)) {
          return InkWell(
            onTap: () {
              AppHaptics.error();
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
      hapticType: BouncingHapticType.medium,
      onPressed: onAction,
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
}

