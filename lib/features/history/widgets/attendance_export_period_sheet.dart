import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';

class AttendanceExportPeriodResult {
  final DateTime startDate;
  final DateTime endDate;
  final String periodLabel;

  const AttendanceExportPeriodResult({
    required this.startDate,
    required this.endDate,
    required this.periodLabel,
  });
}

class AttendanceExportPeriodSheet extends StatefulWidget {
  final String? activeFilterLabel;
  final DateTimeRange? activeDateRange;

  const AttendanceExportPeriodSheet({
    super.key,
    this.activeFilterLabel,
    this.activeDateRange,
  });

  static Future<AttendanceExportPeriodResult?> show(
    BuildContext context, {
    String? activeFilterLabel,
    DateTimeRange? activeDateRange,
  }) {
    return showModalBottomSheet<AttendanceExportPeriodResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AttendanceExportPeriodSheet(
        activeFilterLabel: activeFilterLabel,
        activeDateRange: activeDateRange,
      ),
    );
  }

  @override
  State<AttendanceExportPeriodSheet> createState() =>
      _AttendanceExportPeriodSheetState();
}

class _AttendanceExportPeriodSheetState
    extends State<AttendanceExportPeriodSheet> {
  late final DateTime _now;
  late final DateTime _currentMonthStart;
  late final DateTime _currentMonthEnd;
  late final DateTime _lastMonthStart;
  late final DateTime _lastMonthEnd;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();

    // Bulan Ini (1 .. last day of current month)
    _currentMonthStart = DateTime(_now.year, _now.month, 1);
    _currentMonthEnd = DateTime(_now.year, _now.month + 1, 0);

    // Bulan Lalu (1 .. last day of previous month)
    _lastMonthStart = DateTime(_now.year, _now.month - 1, 1);
    _lastMonthEnd = DateTime(_now.year, _now.month, 0);
  }

  Future<void> _selectCustomMonth() async {
    int selectedYear = _now.year;
    int selectedMonth = _now.month;

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final monthNames = [
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

            return AlertDialog(
              backgroundColor: context.surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pilih Bulan & Tahun',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: selectedYear > _now.year - 5
                            ? () {
                                setDialogState(() {
                                  selectedYear--;
                                });
                              }
                            : null,
                      ),
                      Text(
                        '$selectedYear',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: selectedYear < _now.year + 1
                            ? () {
                                setDialogState(() {
                                  selectedYear++;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              content: SizedBox(
                width: 320,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(12, (index) {
                    final monthIdx = index + 1;
                    final isSelected =
                        selectedMonth == monthIdx && selectedYear == _now.year;
                    return SizedBox(
                      width: 90,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isSelected
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          foregroundColor: isSelected
                              ? AppColors.primary
                              : context.textPrimaryColor,
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : context.borderColor,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(dialogCtx)
                              .pop(DateTime(selectedYear, monthIdx, 1));
                        },
                        child: Text(
                          monthNames[index].substring(0, 3),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null && mounted) {
      final start = DateTime(picked.year, picked.month, 1);
      final end = DateTime(picked.year, picked.month + 1, 0);
      final label = DateFormatter.formatMonthYear(start);

      Navigator.of(context).pop(
        AttendanceExportPeriodResult(
          startDate: start,
          endDate: end,
          periodLabel: label,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMonthLabel = DateFormatter.formatMonthYear(_currentMonthStart);
    final lastMonthLabel = DateFormatter.formatMonthYear(_lastMonthStart);

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Periode Ekspor PDF',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pilih bulan rekapitulasi presensi karyawan',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Option 1: Current Month
          _buildOptionTile(
            key: const Key('export_option_current_month'),
            icon: Icons.calendar_today_rounded,
            title: 'Bulan Ini ($currentMonthLabel)',
            subtitle: '1 - ${_currentMonthEnd.day} $currentMonthLabel',
            isPrimary: true,
            onTap: () {
              Navigator.of(context).pop(
                AttendanceExportPeriodResult(
                  startDate: _currentMonthStart,
                  endDate: _currentMonthEnd,
                  periodLabel: currentMonthLabel,
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // Option 2: Previous Month
          _buildOptionTile(
            key: const Key('export_option_last_month'),
            icon: Icons.history_rounded,
            title: 'Bulan Lalu ($lastMonthLabel)',
            subtitle: '1 - ${_lastMonthEnd.day} $lastMonthLabel',
            onTap: () {
              Navigator.of(context).pop(
                AttendanceExportPeriodResult(
                  startDate: _lastMonthStart,
                  endDate: _lastMonthEnd,
                  periodLabel: lastMonthLabel,
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // Option 3: Select Other Month
          _buildOptionTile(
            key: const Key('export_option_custom_month'),
            icon: Icons.date_range_rounded,
            title: 'Pilih Bulan & Tahun Lain...',
            subtitle: 'Pilih bulan sebelumnya sesuai kebutuhan',
            onTap: _selectCustomMonth,
          ),

          // Option 4 (If Active Filter exists)
          if (widget.activeDateRange != null) ...[
            const SizedBox(height: 10),
            _buildOptionTile(
              key: const Key('export_option_active_filter'),
              icon: Icons.filter_alt_outlined,
              title: 'Sesuai Filter Aktif di Layar',
              subtitle: widget.activeFilterLabel ?? 'Rentang tanggal terpilih',
              onTap: () {
                Navigator.of(context).pop(
                  AttendanceExportPeriodResult(
                    startDate: widget.activeDateRange!.start,
                    endDate: widget.activeDateRange!.end,
                    periodLabel: widget.activeFilterLabel ??
                        '${DateFormatter.formatFullDate(widget.activeDateRange!.start)} s.d ${DateFormatter.formatFullDate(widget.activeDateRange!.end)}',
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    Key? key,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary.withValues(alpha: 0.08)
              : context.surfaceSecondaryColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary ? AppColors.primary : context.borderColor,
            width: isPrimary ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isPrimary ? AppColors.primary : context.textSecondaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isPrimary ? FontWeight.bold : FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: context.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

