import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../providers/history_provider.dart';
import 'history_filter_option_tile.dart';

class HistoryDateFilterSheet extends StatelessWidget {
  const HistoryDateFilterSheet({super.key});

  static void show(BuildContext context, WidgetRef ref) {
    final historyState = ref.read(historyProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Periode Tanggal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
                if (historyState.filter.dateRange != null)
                  TextButton(
                    onPressed: () {
                      ref
                          .read(historyProvider.notifier)
                          .setDateRangeFilter(null);
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Hapus Filter',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            HistoryFilterOptionTile(
              title: 'Semua Waktu',
              subtitle: 'Tampilkan seluruh riwayat presensi',
              isSelected: historyState.filter.dateRange == null,
              onTap: () {
                ref.read(historyProvider.notifier).setDateRangeFilter(null);
                Navigator.pop(ctx);
              },
            ),
            HistoryFilterOptionTile(
              title: 'Hari Ini',
              subtitle:
                  '${today.day} ${formatIndoDateString(today.toIso8601String()).split(', ').last}',
              isSelected: historyState.filter.dateRangeLabel == 'Hari Ini',
              onTap: () {
                final range = DateTimeRange(start: today, end: today);
                ref
                    .read(historyProvider.notifier)
                    .setDateRangeFilter(range, 'Hari Ini');
                Navigator.pop(ctx);
              },
            ),
            HistoryFilterOptionTile(
              title: '7 Hari Terakhir',
              subtitle: 'Presensi satu minggu ke belakang',
              isSelected:
                  historyState.filter.dateRangeLabel == '7 Hari Terakhir',
              onTap: () {
                final range = DateTimeRange(
                  start: today.subtract(const Duration(days: 6)),
                  end: today,
                );
                ref
                    .read(historyProvider.notifier)
                    .setDateRangeFilter(range, '7 Hari Terakhir');
                Navigator.pop(ctx);
              },
            ),
            HistoryFilterOptionTile(
              title: 'Bulan Ini',
              subtitle:
                  '1 - ${today.day} ${formatIndoDateString(today.toIso8601String()).split(', ').last}',
              isSelected: historyState.filter.dateRangeLabel == 'Bulan Ini',
              onTap: () {
                final startOfMonth = DateTime(today.year, today.month, 1);
                final range = DateTimeRange(start: startOfMonth, end: today);
                ref
                    .read(historyProvider.notifier)
                    .setDateRangeFilter(range, 'Bulan Ini');
                Navigator.pop(ctx);
              },
            ),
            HistoryFilterOptionTile(
              title: 'Bulan Lalu',
              subtitle: _formatPreviousMonthSubtitle(now),
              isSelected: historyState.filter.dateRangeLabel == 'Bulan Lalu',
              onTap: () {
                final firstDayCurrentMonth = DateTime(now.year, now.month, 1);
                final lastDayPrevMonth = firstDayCurrentMonth.subtract(
                  const Duration(days: 1),
                );
                final firstDayPrevMonth = DateTime(
                  lastDayPrevMonth.year,
                  lastDayPrevMonth.month,
                  1,
                );
                final range = DateTimeRange(
                  start: firstDayPrevMonth,
                  end: DateTime(
                    lastDayPrevMonth.year,
                    lastDayPrevMonth.month,
                    lastDayPrevMonth.day,
                  ),
                );
                ref
                    .read(historyProvider.notifier)
                    .setDateRangeFilter(range, 'Bulan Lalu');
                Navigator.pop(ctx);
              },
            ),
            HistoryFilterOptionTile(
              title: 'Pilih Rentang Tanggal Manual...',
              subtitle: 'Tentukan tanggal mulai dan selesai sendiri',
              isSelected:
                  historyState.filter.dateRange != null &&
                  historyState.filter.dateRangeLabel != 'Hari Ini' &&
                  historyState.filter.dateRangeLabel != '7 Hari Terakhir' &&
                  historyState.filter.dateRangeLabel != 'Bulan Ini' &&
                  historyState.filter.dateRangeLabel != 'Bulan Lalu',
              icon: Icons.date_range_rounded,
              onTap: () {
                Navigator.pop(ctx);
                pickCustomDateRange(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> pickCustomDateRange(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final historyState = ref.read(historyProvider);
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      initialDateRange:
          historyState.filter.dateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      cancelText: 'Batal',
      confirmText: 'Pilih',
      saveText: 'Simpan',
      helpText: 'Pilih Rentang Tanggal',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: context.surfaceColor,
              onSurface: context.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final label = formatDateRangeLabel(picked);
      ref.read(historyProvider.notifier).setDateRangeFilter(picked, label);
    }
  }

  static String formatDateRangeLabel(DateTimeRange range) {
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
    final startDay = range.start.day;
    final startMonth = months[range.start.month - 1];
    final endDay = range.end.day;
    final endMonth = months[range.end.month - 1];

    if (range.start.year == range.end.year &&
        range.start.month == range.end.month &&
        range.start.day == range.end.day) {
      return '$startDay $startMonth ${range.start.year}';
    }
    if (range.start.year == range.end.year) {
      return '$startDay $startMonth - $endDay $endMonth';
    }
    return '$startDay $startMonth ${range.start.year} - $endDay $endMonth ${range.end.year}';
  }

  static String _formatPreviousMonthSubtitle(DateTime now) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final firstDayCurrentMonth = DateTime(now.year, now.month, 1);
    final lastDayPrevMonth = firstDayCurrentMonth.subtract(const Duration(days: 1));
    final prevMonthName = months[lastDayPrevMonth.month - 1];
    return '1 - ${lastDayPrevMonth.day} $prevMonthName ${lastDayPrevMonth.year}';
  }

  static String formatIndoDateString(String dateStr) {
    final dt = DateTime.tryParse(dateStr);
    if (dt != null) {
      const months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
    }
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
