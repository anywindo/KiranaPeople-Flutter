import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/attendance_model.dart';

class HistorySummaryCard extends StatelessWidget {
  final List<AttendanceRecord> records;

  const HistorySummaryCard({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    // Calculate metrics
    final totalDays = records.length;
    int onTimeCount = 0;
    int lateCount = 0;

    for (final record in records) {
      if (record.isLate) {
        lateCount++;
      } else {
        onTimeCount++;
      }
    }

    // Determine current month label in Indonesian
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
    final now = DateTime.now();
    final monthLabel = '${months[now.month - 1]} ${now.year}';

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.35 : 0.08,
            ),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.18 : 0.04,
            ),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title & Month
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: isDark ? 0.20 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(
                          alpha: isDark ? 0.40 : 0.25,
                        ),
                        width: 1.0,
                      ),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ringkasan Kehadiran',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: context.surfaceSecondaryColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  monthLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3 Metric Tiles Row
          Row(
            children: [
              // Total Hadir Tile
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'Total Hadir',
                  value: '$totalDays',
                  unit: 'Hari',
                  valueColor: context.textPrimaryColor,
                  bgColor: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderColor: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              const SizedBox(width: 8),

              // Tepat Waktu Tile
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'Tepat Waktu',
                  value: '$onTimeCount',
                  unit: 'Hari',
                  valueColor: isDark
                      ? const Color(0xFF34D399)
                      : const Color(0xFF16A34A),
                  bgColor: isDark
                      ? const Color(0xFF064E3B).withValues(alpha: 0.25)
                      : const Color(0xFFF0FDF4),
                  borderColor: isDark
                      ? const Color(0xFF065F46)
                      : const Color(0xFFBBF7D0),
                ),
              ),
              const SizedBox(width: 8),

              // Terlambat Tile
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'Terlambat',
                  value: '$lateCount',
                  unit: 'Hari',
                  valueColor: isDark
                      ? const Color(0xFFF87171)
                      : const Color(0xFFE11D48),
                  bgColor: isDark
                      ? const Color(0xFF4C1D24).withValues(alpha: 0.35)
                      : const Color(0xFFFFF1F2),
                  borderColor: isDark
                      ? const Color(0xFF7F1D1D)
                      : const Color(0xFFFFCDD2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
    required String unit,
    required Color valueColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: context.textMutedColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

