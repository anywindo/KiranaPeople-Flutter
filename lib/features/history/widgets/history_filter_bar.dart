import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../providers/history_provider.dart';
import 'history_filter_sheet.dart';

class HistoryFilterBar extends ConsumerWidget {
  const HistoryFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyProvider);
    final filter = historyState.filter;
    final notifier = ref.read(historyProvider.notifier);
    final isDark = context.isDarkMode;

    final isCustomDateSelected = filter.dateRange != null &&
        filter.dateRangeLabel != 'Hari Ini' &&
        filter.dateRangeLabel != '7 Hari' &&
        filter.dateRangeLabel != '7 Hari Terakhir' &&
        filter.dateRangeLabel != 'Bulan Ini' &&
        filter.dateRangeLabel != 'Bulan Lalu';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Status: Semua
          _buildQuickFilterPill(
            context,
            label: 'Semua',
            isSelected: filter.status == AttendanceHistoryStatusFilter.all &&
                filter.dateRange == null &&
                (filter.shift == null || filter.shift == 'Semua Shift'),
            onTap: () {
              AppHaptics.selection();
              notifier.resetFilter();
            },
          ),
          const SizedBox(width: 8),

          // Status: Tepat Waktu
          _buildQuickFilterPill(
            context,
            label: 'Tepat Waktu',
            icon: Icons.check_circle_rounded,
            isSelected: filter.status == AttendanceHistoryStatusFilter.onTime,
            activeColor: isDark
                ? const Color(0xFF34D399)
                : const Color(0xFF15803D),
            activeBg: isDark
                ? const Color(0xFF064E3B).withValues(alpha: 0.5)
                : const Color(0xFFDCFCE7),
            onTap: () {
              AppHaptics.selection();
              notifier.setStatusFilter(
                filter.status == AttendanceHistoryStatusFilter.onTime
                    ? AttendanceHistoryStatusFilter.all
                    : AttendanceHistoryStatusFilter.onTime,
              );
            },
          ),
          const SizedBox(width: 8),

          // Status: Terlambat
          _buildQuickFilterPill(
            context,
            label: 'Terlambat',
            icon: Icons.alarm_rounded,
            isSelected: filter.status == AttendanceHistoryStatusFilter.late,
            activeColor: isDark
                ? const Color(0xFFF87171)
                : const Color(0xFFE11D48),
            activeBg: isDark
                ? const Color(0xFF4C1D24).withValues(alpha: 0.5)
                : const Color(0xFFFFF1F2),
            onTap: () {
              AppHaptics.selection();
              notifier.setStatusFilter(
                filter.status == AttendanceHistoryStatusFilter.late
                    ? AttendanceHistoryStatusFilter.all
                    : AttendanceHistoryStatusFilter.late,
              );
            },
          ),
          const SizedBox(width: 8),

          // Subtle Vertical Divider
          Container(
            height: 20,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
          const SizedBox(width: 8),

          // Preset: Hari Ini
          _buildQuickFilterPill(
            context,
            label: 'Hari Ini',
            isSelected: filter.dateRangeLabel == 'Hari Ini',
            onTap: () {
              AppHaptics.selection();
              if (filter.dateRangeLabel == 'Hari Ini') {
                notifier.setDateRangeFilter(null);
              } else {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                notifier.setDateRangeFilter(
                  DateTimeRange(start: today, end: today),
                  'Hari Ini',
                );
              }
            },
          ),
          const SizedBox(width: 8),

          // Preset: 7 Hari
          _buildQuickFilterPill(
            context,
            label: '7 Hari',
            isSelected: filter.dateRangeLabel == '7 Hari Terakhir',
            onTap: () {
              AppHaptics.selection();
              if (filter.dateRangeLabel == '7 Hari Terakhir') {
                notifier.setDateRangeFilter(null);
              } else {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                notifier.setDateRangeFilter(
                  DateTimeRange(
                    start: today.subtract(const Duration(days: 6)),
                    end: today,
                  ),
                  '7 Hari Terakhir',
                );
              }
            },
          ),
          const SizedBox(width: 8),

          // Preset: Bulan Ini
          _buildQuickFilterPill(
            context,
            label: 'Bulan Ini',
            isSelected: filter.dateRangeLabel == 'Bulan Ini',
            onTap: () {
              AppHaptics.selection();
              if (filter.dateRangeLabel == 'Bulan Ini') {
                notifier.setDateRangeFilter(null);
              } else {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                notifier.setDateRangeFilter(
                  DateTimeRange(
                    start: DateTime(today.year, today.month, 1),
                    end: today,
                  ),
                  'Bulan Ini',
                );
              }
            },
          ),
          const SizedBox(width: 8),

          // Preset: Bulan Lalu
          _buildQuickFilterPill(
            context,
            label: 'Bulan Lalu',
            isSelected: filter.dateRangeLabel == 'Bulan Lalu',
            onTap: () {
              AppHaptics.selection();
              if (filter.dateRangeLabel == 'Bulan Lalu') {
                notifier.setDateRangeFilter(null);
              } else {
                final now = DateTime.now();
                final firstDayCurrentMonth = DateTime(now.year, now.month, 1);
                final lastDayPrevMonth = firstDayCurrentMonth.subtract(
                  const Duration(days: 1),
                );
                final firstDayPrevMonth = DateTime(
                  lastDayPrevMonth.year,
                  lastDayPrevMonth.month,
                  1,
                );
                notifier.setDateRangeFilter(
                  DateTimeRange(
                    start: firstDayPrevMonth,
                    end: DateTime(
                      lastDayPrevMonth.year,
                      lastDayPrevMonth.month,
                      lastDayPrevMonth.day,
                    ),
                  ),
                  'Bulan Lalu',
                );
              }
            },
          ),
          const SizedBox(width: 8),

          // Date Range Chip (Custom Calendar Sheet)
          _buildQuickFilterPill(
            context,
            label: isCustomDateSelected
                ? (filter.dateRangeLabel ?? 'Rentang Tanggal')
                : 'Tanggal',
            icon: Icons.calendar_month_rounded,
            trailingIcon: isCustomDateSelected
                ? Icons.close_rounded
                : Icons.keyboard_arrow_down_rounded,
            isSelected: isCustomDateSelected,
            onTap: () {
              AppHaptics.selection();
              HistoryFilterSheet.showDateFilter(context, ref);
            },
            onTrailingTap: isCustomDateSelected
                ? () {
                    AppHaptics.selection();
                    notifier.setDateRangeFilter(null);
                  }
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
              isSelected: filter.shift != null && filter.shift != 'Semua Shift',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: context.surfaceSecondaryColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: context.isDarkMode
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                    width: 1.2,
                  ),
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
        : (context.isDarkMode
              ? const Color(0xFF334155)
              : const Color(0xFFCBD5E1));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.2),
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
