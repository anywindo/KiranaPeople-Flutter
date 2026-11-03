import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/history_provider.dart';
import 'history_filter_sheet.dart';

class HistoryFilterBar extends ConsumerWidget {
  const HistoryFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyProvider);
    final filter = historyState.filter;
    final notifier = ref.read(historyProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: context.scaffoldBg,
        border: Border(
          bottom: BorderSide(
            color: context.borderColor.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Status: Semua
            _buildQuickFilterPill(
              context,
              label: 'Semua',
              isSelected: filter.status == AttendanceHistoryStatusFilter.all,
              onTap: () =>
                  notifier.setStatusFilter(AttendanceHistoryStatusFilter.all),
            ),
            const SizedBox(width: 8),

            // Status: Tepat Waktu
            _buildQuickFilterPill(
              context,
              label: 'Tepat Waktu',
              icon: Icons.check_circle_rounded,
              isSelected: filter.status == AttendanceHistoryStatusFilter.onTime,
              activeColor: const Color(0xFF15803D),
              activeBg: const Color(0xFFDCFCE7),
              onTap: () => notifier.setStatusFilter(
                filter.status == AttendanceHistoryStatusFilter.onTime
                    ? AttendanceHistoryStatusFilter.all
                    : AttendanceHistoryStatusFilter.onTime,
              ),
            ),
            const SizedBox(width: 8),

            // Status: Terlambat
            _buildQuickFilterPill(
              context,
              label: 'Terlambat',
              icon: Icons.alarm_rounded,
              isSelected: filter.status == AttendanceHistoryStatusFilter.late,
              activeColor: const Color(0xFFE11D48),
              activeBg: const Color(0xFFFFF1F2),
              onTap: () => notifier.setStatusFilter(
                filter.status == AttendanceHistoryStatusFilter.late
                    ? AttendanceHistoryStatusFilter.all
                    : AttendanceHistoryStatusFilter.late,
              ),
            ),
            const SizedBox(width: 8),

            // Date Range Chip
            _buildQuickFilterPill(
              context,
              label: filter.dateRange != null
                  ? (filter.dateRangeLabel ?? 'Rentang Tanggal')
                  : 'Tanggal',
              icon: Icons.calendar_month_rounded,
              trailingIcon: filter.dateRange != null
                  ? Icons.close_rounded
                  : Icons.keyboard_arrow_down_rounded,
              isSelected: filter.dateRange != null,
              onTap: () => HistoryFilterSheet.showDateFilter(context, ref),
              onTrailingTap: filter.dateRange != null
                  ? () => notifier.setDateRangeFilter(null)
                  : null,
            ),

            // Shift Chip (if shifts available)
            if (historyState.availableShifts.length > 2) ...[
              const SizedBox(width: 8),
              _buildQuickFilterPill(
                context,
                label: filter.shift != null && filter.shift != 'Semua Shift'
                    ? filter.shift!
                    : 'Shift',
                icon: Icons.access_time_rounded,
                trailingIcon:
                    filter.shift != null && filter.shift != 'Semua Shift'
                        ? Icons.close_rounded
                        : Icons.keyboard_arrow_down_rounded,
                isSelected:
                    filter.shift != null && filter.shift != 'Semua Shift',
                onTap: () => HistoryFilterSheet.showShiftFilter(
                  context,
                  ref,
                  historyState.availableShifts,
                ),
                onTrailingTap:
                    filter.shift != null && filter.shift != 'Semua Shift'
                        ? () => notifier.setShiftFilter(null)
                        : null,
              ),
            ],

            // Reset chip (when filter active)
            if (filter.isActive) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () => notifier.resetFilter(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: context.surfaceSecondaryColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 14,
                        color: context.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilterPill(
    BuildContext context, {
    required String label,
    IconData? icon,
    IconData? trailingIcon,
    required bool isSelected,
    Color? activeColor,
    Color? activeBg,
    required VoidCallback onTap,
    VoidCallback? onTrailingTap,
  }) {
    final textColor = isSelected
        ? (activeColor ?? Colors.white)
        : context.textSecondaryColor;
    final bgColor = isSelected
        ? (activeBg ?? AppColors.primary)
        : context.surfaceColor;
    final borderColor = isSelected
        ? (activeColor ?? AppColors.primary)
        : context.borderColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: textColor),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: textColor,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onTrailingTap ?? onTap,
                child: Icon(trailingIcon, size: 14, color: textColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

