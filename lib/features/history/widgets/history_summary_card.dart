import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/widgets/bouncing_button.dart';
import '../../../data/models/attendance_event_model.dart';
import '../../../data/models/attendance_model.dart';

class HistorySummaryCard extends StatefulWidget {
  final List<AttendanceRecord> records;
  final bool initiallyExpanded;
  final VoidCallback? onExportPdf;

  const HistorySummaryCard({
    super.key,
    required this.records,
    this.initiallyExpanded = false,
    this.onExportPdf,
  });

  @override
  State<HistorySummaryCard> createState() => _HistorySummaryCardState();
}

class _HistorySummaryCardState extends State<HistorySummaryCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  AnimationController? _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _initAnimations();
  }

  @override
  void reassemble() {
    super.reassemble();
    _initAnimations();
  }

  void _initAnimations() {
    _controller ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: widget.initiallyExpanded ? 1.0 : 0.0,
    );

    final curved = CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );

    _expandAnimation = curved;

    _fadeAnimation = CurvedAnimation(
      parent: _controller!,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
      reverseCurve: const Interval(0.0, 0.65, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(curved);

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(curved);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toggle() {
    AppHaptics.selection();
    _initAnimations();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller?.forward();
      } else {
        _controller?.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _initAnimations();
    final isDark = context.isDarkMode;

    // Calculate core metrics
    final totalDays = widget.records.length;
    int onTimeCount = 0;
    int lateCount = 0;
    int totalCheckInMinutes = 0;
    int checkInCount = 0;
    int totalCheckOutMinutes = 0;
    int checkOutCount = 0;
    int totalWorkMinutes = 0;

    for (final record in widget.records) {
      if (record.isLate) {
        lateCount++;
      } else {
        onTimeCount++;
      }

      DateTime? startShiftTime;
      DateTime? endShiftTime;
      DateTime? startBreakTime;
      DateTime? endBreakTime;

      for (final event in record.events) {
        final parsed = DateTime.tryParse(event.timestamp);
        if (parsed == null) continue;
        final local = parsed.isUtc ? parsed.toLocal() : parsed;

        switch (event.eventType) {
          case AttendanceEventType.startShift:
            startShiftTime = local;
            break;
          case AttendanceEventType.endShift:
            endShiftTime = local;
            break;
          case AttendanceEventType.startBreak:
            startBreakTime = local;
            break;
          case AttendanceEventType.endBreak:
            endBreakTime = local;
            break;
        }
      }

      if (startShiftTime != null) {
        totalCheckInMinutes += startShiftTime.hour * 60 + startShiftTime.minute;
        checkInCount++;
      }

      if (endShiftTime != null) {
        totalCheckOutMinutes += endShiftTime.hour * 60 + endShiftTime.minute;
        checkOutCount++;
      }

      if (startShiftTime != null && endShiftTime != null) {
        int workMins = endShiftTime.difference(startShiftTime).inMinutes;
        if (startBreakTime != null && endBreakTime != null) {
          final breakMins = endBreakTime.difference(startBreakTime).inMinutes;
          if (breakMins > 0 && breakMins < workMins) {
            workMins -= breakMins;
          }
        }
        if (workMins > 0) {
          totalWorkMinutes += workMins;
        }
      }
    }

    final onTimeRatio = totalDays > 0 ? (onTimeCount / totalDays).clamp(0.0, 1.0) : 1.0;
    final onTimePercent = (onTimeRatio * 100).round();

    // Average Check-in
    String avgCheckInStr = '--:--';
    if (checkInCount > 0) {
      final avgMins = totalCheckInMinutes ~/ checkInCount;
      final h = (avgMins ~/ 60).toString().padLeft(2, '0');
      final m = (avgMins % 60).toString().padLeft(2, '0');
      avgCheckInStr = '$h:$m WIB';
    }

    // Average Check-out
    String avgCheckOutStr = '--:--';
    if (checkOutCount > 0) {
      final avgMins = totalCheckOutMinutes ~/ checkOutCount;
      final h = (avgMins ~/ 60).toString().padLeft(2, '0');
      final m = (avgMins % 60).toString().padLeft(2, '0');
      avgCheckOutStr = '$h:$m WIB';
    }

    // Total Working Hours
    String totalWorkStr = '--';
    if (totalWorkMinutes > 0) {
      totalWorkStr = '${totalWorkMinutes ~/ 60}j ${totalWorkMinutes % 60}m';
    }

    // Average Daily Working Duration
    String avgDailyWorkStr = '--';
    if (checkOutCount > 0 && totalWorkMinutes > 0) {
      final avgDayMins = totalWorkMinutes ~/ checkOutCount;
      avgDailyWorkStr = '${avgDayMins ~/ 60}j ${avgDayMins % 60}m';
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
          // Header Row: Title, Month & Expand Trigger
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Ringkasan Kehadiran',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      RotationTransition(
                        turns: _rotateAnimation,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: context.textSecondaryColor,
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
            ),
          ),
          const SizedBox(height: 14),

          // 3 Core Metric Tiles Row
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

          // Fluid Size + Fade + Slide Staggered Expansion Section
          AnimatedBuilder(
            animation: _controller!,
            builder: (context, child) {
              if (_controller!.value == 0.0 && !_isExpanded) {
                return const SizedBox.shrink();
              }
              return SizeTransition(
                sizeFactor: _expandAnimation,
                alignment: Alignment.topCenter,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: child,
                  ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                const SizedBox(height: 14),

                // On-Time Ratio Header & Animated Track
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tingkat Ketepatan Waktu',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.textSecondaryColor,
                      ),
                    ),
                    Text(
                      '$onTimePercent%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: onTimePercent >= 85
                            ? (isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A))
                            : (isDark ? const Color(0xFFF87171) : const Color(0xFFE11D48)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        width: double.infinity,
                        color: lateCount > 0
                            ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFFCDD2))
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                      ),
                      AnimatedBuilder(
                        animation: _expandAnimation,
                        builder: (context, _) {
                          return FractionallySizedBox(
                            widthFactor: onTimeRatio * _expandAnimation.value,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2x2 Analytics Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailMetric(
                        context,
                        icon: Icons.login_rounded,
                        iconColor: const Color(0xFF3B82F6),
                        label: 'Rata-rata Masuk',
                        value: avgCheckInStr,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDetailMetric(
                        context,
                        icon: Icons.logout_rounded,
                        iconColor: const Color(0xFFF97316),
                        label: 'Rata-rata Pulang',
                        value: avgCheckOutStr,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailMetric(
                        context,
                        icon: Icons.timer_rounded,
                        iconColor: const Color(0xFF8B5CF6),
                        label: 'Total Jam Kerja',
                        value: totalWorkStr,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDetailMetric(
                        context,
                        icon: Icons.av_timer_rounded,
                        iconColor: const Color(0xFF10B981),
                        label: 'Rata-rata Harian',
                        value: avgDailyWorkStr,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                if (widget.onExportPdf != null) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    key: const Key('summary_export_pdf_button'),
                    onTap: widget.onExportPdf,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Unduh / Cetak Rekap PDF',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
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

          const SizedBox(height: 10),

          // Expander Toggle Action Button with AnimatedSwitcher
          Center(
            child: BouncingButton(
              scaleDown: 0.94,
              hapticType: BouncingHapticType.selection,
              onPressed: _toggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: Text(
                        _isExpanded ? 'Sembunyikan Analisis' : 'Lihat Analisis Detail',
                        key: ValueKey<bool>(_isExpanded),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    RotationTransition(
                      turns: _rotateAnimation,
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 15,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

  Widget _buildDetailMetric(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: context.textMutedColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
