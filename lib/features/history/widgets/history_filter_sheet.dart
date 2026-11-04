import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/history_provider.dart';
import 'filter/history_date_filter_sheet.dart';
import 'filter/history_filter_chip.dart';
import 'filter/history_shift_filter_sheet.dart';

export 'filter/history_date_filter_sheet.dart';
export 'filter/history_filter_chip.dart';
export 'filter/history_filter_option_tile.dart';
export 'filter/history_shift_filter_sheet.dart';

class HistoryFilterSheet extends ConsumerStatefulWidget {
  const HistoryFilterSheet({super.key});

  static void showFullFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const HistoryFilterSheet(),
    );
  }

  static void showDateFilter(BuildContext context, WidgetRef ref) {
    HistoryDateFilterSheet.show(context, ref);
  }

  static void showShiftFilter(
    BuildContext context,
    WidgetRef ref,
    List<String> shifts,
  ) {
    HistoryShiftFilterSheet.show(context, ref, shifts);
  }

  static Future<void> pickCustomDateRange(
    BuildContext context,
    WidgetRef ref,
  ) {
    return HistoryDateFilterSheet.pickCustomDateRange(context, ref);
  }

  static String formatDateRangeLabel(DateTimeRange range) {
    return HistoryDateFilterSheet.formatDateRangeLabel(range);
  }

  @override
  ConsumerState<HistoryFilterSheet> createState() => _HistoryFilterSheetState();
}

class _HistoryFilterSheetState extends ConsumerState<HistoryFilterSheet> {
  late AttendanceHistoryStatusFilter _tempStatus;
  DateTimeRange? _tempRange;
  String? _tempRangeLabel;
  late String _tempShift;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(historyProvider).filter;
    _tempStatus = filter.status;
    _tempRange = filter.dateRange;
    _tempRangeLabel = filter.dateRangeLabel;
    _tempShift = filter.shift ?? 'Semua Shift';
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
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
                  'Filter Riwayat Presensi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: context.textSecondaryColor,
                ),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // 1. Status Kehadiran
            Text(
              'Status Kehadiran',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: context.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                HistoryFilterChip(
                  label: 'Semua Status',
                  isSelected: _tempStatus == AttendanceHistoryStatusFilter.all,
                  onTap: () => setState(
                    () => _tempStatus = AttendanceHistoryStatusFilter.all,
                  ),
                ),
                HistoryFilterChip(
                  label: 'Tepat Waktu',
                  isSelected:
                      _tempStatus == AttendanceHistoryStatusFilter.onTime,
                  selectedColor: const Color(0xFF15803D),
                  selectedBg: const Color(0xFFDCFCE7),
                  onTap: () => setState(
                    () => _tempStatus = AttendanceHistoryStatusFilter.onTime,
                  ),
                ),
                HistoryFilterChip(
                  label: 'Terlambat',
                  isSelected: _tempStatus == AttendanceHistoryStatusFilter.late,
                  selectedColor: const Color(0xFFE11D48),
                  selectedBg: const Color(0xFFFFF1F2),
                  onTap: () => setState(
                    () => _tempStatus = AttendanceHistoryStatusFilter.late,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Periode / Tanggal
            Text(
              'Periode Tanggal',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: context.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                HistoryFilterChip(
                  label: 'Semua',
                  isSelected: _tempRange == null,
                  onTap: () => setState(() {
                    _tempRange = null;
                    _tempRangeLabel = null;
                  }),
                ),
                HistoryFilterChip(
                  label: 'Hari Ini',
                  isSelected: _tempRangeLabel == 'Hari Ini',
                  onTap: () {
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    setState(() {
                      _tempRange = DateTimeRange(start: today, end: today);
                      _tempRangeLabel = 'Hari Ini';
                    });
                  },
                ),
                HistoryFilterChip(
                  label: '7 Hari Terakhir',
                  isSelected: _tempRangeLabel == '7 Hari Terakhir',
                  onTap: () {
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    setState(() {
                      _tempRange = DateTimeRange(
                        start: today.subtract(const Duration(days: 6)),
                        end: today,
                      );
                      _tempRangeLabel = '7 Hari Terakhir';
                    });
                  },
                ),
                HistoryFilterChip(
                  label: 'Bulan Ini',
                  isSelected: _tempRangeLabel == 'Bulan Ini',
                  onTap: () {
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    setState(() {
                      _tempRange = DateTimeRange(
                        start: DateTime(today.year, today.month, 1),
                        end: today,
                      );
                      _tempRangeLabel = 'Bulan Ini';
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: _tempRange != null &&
                          _tempRangeLabel != 'Hari Ini' &&
                          _tempRangeLabel != '7 Hari Terakhir' &&
                          _tempRangeLabel != 'Bulan Ini'
                      ? AppColors.primary
                      : context.borderColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(now.year - 3),
                  lastDate: DateTime(now.year + 1),
                  initialDateRange: _tempRange ??
                      DateTimeRange(
                        start: now.subtract(const Duration(days: 30)),
                        end: now,
                      ),
                  cancelText: 'Batal',
                  confirmText: 'Pilih',
                  saveText: 'Simpan',
                  helpText: 'Pilih Rentang Tanggal',
                  builder: (ctx, child) {
                    return Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: AppColors.primary,
                          onPrimary: Colors.white,
                          surface: ctx.surfaceColor,
                          onSurface: ctx.textPrimaryColor,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    _tempRange = picked;
                    _tempRangeLabel =
                        HistoryFilterSheet.formatDateRangeLabel(picked);
                  });
                }
              },
              icon: const Icon(Icons.date_range_rounded, size: 18),
              label: Text(
                _tempRange != null &&
                        _tempRangeLabel != 'Hari Ini' &&
                        _tempRangeLabel != '7 Hari Terakhir' &&
                        _tempRangeLabel != 'Bulan Ini'
                    ? 'Rentang: $_tempRangeLabel'
                    : 'Pilih Rentang Tanggal Manual...',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Shift Kerja
            if (historyState.availableShifts.length > 1) ...[
              Text(
                'Shift Kerja',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: context.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: historyState.availableShifts.map((s) {
                  final isSelected = _tempShift == s;
                  return HistoryFilterChip(
                    label: s,
                    isSelected: isSelected,
                    onTap: () => setState(() => _tempShift = s),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.textSecondaryColor,
                      side: BorderSide(color: context.borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      ref.read(historyProvider.notifier).resetFilter();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Reset',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      final notifier = ref.read(historyProvider.notifier);
                      notifier.setStatusFilter(_tempStatus);
                      notifier.setDateRangeFilter(_tempRange, _tempRangeLabel);
                      notifier.setShiftFilter(
                        _tempShift == 'Semua Shift' ? null : _tempShift,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Terapkan Filter',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
