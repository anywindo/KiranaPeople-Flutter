import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/history_provider.dart';

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
            _buildSheetOptionTile(
              context,
              title: 'Semua Waktu',
              subtitle: 'Tampilkan seluruh riwayat presensi',
              isSelected: historyState.filter.dateRange == null,
              onTap: () {
                ref.read(historyProvider.notifier).setDateRangeFilter(null);
                Navigator.pop(ctx);
              },
            ),
            _buildSheetOptionTile(
              context,
              title: 'Hari Ini',
              subtitle:
                  '${today.day} ${_formatIndoDateString(today.toIso8601String()).split(', ').last}',
              isSelected: historyState.filter.dateRangeLabel == 'Hari Ini',
              onTap: () {
                final range = DateTimeRange(start: today, end: today);
                ref
                    .read(historyProvider.notifier)
                    .setDateRangeFilter(range, 'Hari Ini');
                Navigator.pop(ctx);
              },
            ),
            _buildSheetOptionTile(
              context,
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
            _buildSheetOptionTile(
              context,
              title: 'Bulan Ini',
              subtitle:
                  '1 - ${today.day} ${_formatIndoDateString(today.toIso8601String()).split(', ').last}',
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
            _buildSheetOptionTile(
              context,
              title: 'Pilih Rentang Tanggal Manual...',
              subtitle: 'Tentukan tanggal mulai dan selesai sendiri',
              isSelected: historyState.filter.dateRange != null &&
                  historyState.filter.dateRangeLabel != 'Hari Ini' &&
                  historyState.filter.dateRangeLabel != '7 Hari Terakhir' &&
                  historyState.filter.dateRangeLabel != 'Bulan Ini',
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

  static void showShiftFilter(
    BuildContext context,
    WidgetRef ref,
    List<String> shifts,
  ) {
    final historyState = ref.read(historyProvider);
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
            Text(
              'Filter Shift Kerja',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            ...shifts.map((s) {
              final isSelected =
                  (historyState.filter.shift ?? 'Semua Shift') == s;
              return _buildSheetOptionTile(
                context,
                title: s,
                isSelected: isSelected,
                onTap: () {
                  ref
                      .read(historyProvider.notifier)
                      .setShiftFilter(s == 'Semua Shift' ? null : s);
                  Navigator.pop(ctx);
                },
              );
            }),
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
      initialDateRange: historyState.filter.dateRange ??
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

  static String _formatIndoDateString(String dateStr) {
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

  static Widget _buildSheetOptionTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required bool isSelected,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 20,
                color:
                    isSelected ? AppColors.primary : context.textSecondaryColor,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : context.textPrimaryColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textMutedColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
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

            // 1. Status Filter
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
                _buildChip(
                  context,
                  label: 'Semua Status',
                  isSelected: _tempStatus == AttendanceHistoryStatusFilter.all,
                  onTap: () => setState(
                    () => _tempStatus = AttendanceHistoryStatusFilter.all,
                  ),
                ),
                _buildChip(
                  context,
                  label: 'Tepat Waktu',
                  isSelected:
                      _tempStatus == AttendanceHistoryStatusFilter.onTime,
                  selectedColor: const Color(0xFF15803D),
                  selectedBg: const Color(0xFFDCFCE7),
                  onTap: () => setState(
                    () => _tempStatus = AttendanceHistoryStatusFilter.onTime,
                  ),
                ),
                _buildChip(
                  context,
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
                _buildChip(
                  context,
                  label: 'Semua',
                  isSelected: _tempRange == null,
                  onTap: () => setState(() {
                    _tempRange = null;
                    _tempRangeLabel = null;
                  }),
                ),
                _buildChip(
                  context,
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
                _buildChip(
                  context,
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
                _buildChip(
                  context,
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

            // 3. Shift Filter
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
                  return _buildChip(
                    context,
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

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    Color? selectedColor,
    Color? selectedBg,
    required VoidCallback onTap,
  }) {
    final activeBg = selectedBg ?? AppColors.primary.withValues(alpha: 0.12);
    final activeText = selectedColor ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : context.surfaceSecondaryColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeText : context.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? activeText : context.textSecondaryColor,
          ),
        ),
      ),
    );
  }
}

