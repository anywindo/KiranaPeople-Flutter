import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/widgets/bouncing_button.dart';
import '../../../data/models/attendance_event_model.dart';
import '../../../data/models/attendance_submission_result.dart';

class AttendanceSuccessSheet extends StatefulWidget {
  final AttendanceSubmissionResult result;

  const AttendanceSuccessSheet({
    super.key,
    required this.result,
  });

  static Future<void> show(
    BuildContext context, {
    required AttendanceSubmissionResult result,
  }) {
    AppHaptics.success();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AttendanceSuccessSheet(result: result),
    );
  }

  @override
  State<AttendanceSuccessSheet> createState() => _AttendanceSuccessSheetState();
}

class _AttendanceSuccessSheetState extends State<AttendanceSuccessSheet>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _countdownController;
  Timer? _autoDismissTimer;

  static const _autoDismissDuration = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _scaleController.forward();

    _countdownController = AnimationController(
      vsync: this,
      duration: _autoDismissDuration,
    )..reverse(from: 1.0);

    _autoDismissTimer = Timer(_autoDismissDuration, () {
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _countdownController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _autoDismissTimer?.cancel();
    AppHaptics.selection();
    Navigator.of(context).maybePop();
  }

  static String _formatIndoFullDate(DateTime dt) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
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

    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '$dayName, ${dt.day} $monthName ${dt.year}';
  }

  static String _formatTimeWithWib(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s WIB';
  }

  IconData _getEventIcon(AttendanceEventType type) {
    switch (type) {
      case AttendanceEventType.startShift:
        return Icons.work_rounded;
      case AttendanceEventType.startBreak:
        return Icons.coffee_rounded;
      case AttendanceEventType.endBreak:
        return Icons.business_center_rounded;
      case AttendanceEventType.endShift:
        return Icons.home_rounded;
    }
  }

  Color _getEventColor(AttendanceEventType type) {
    switch (type) {
      case AttendanceEventType.startShift:
        return const Color(0xFF10B981);
      case AttendanceEventType.startBreak:
        return const Color(0xFFF59E0B);
      case AttendanceEventType.endBreak:
        return const Color(0xFF0D9488);
      case AttendanceEventType.endShift:
        return const Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final res = widget.result;
    final eventColor = _getEventColor(res.action);
    final eventIcon = _getEventIcon(res.action);

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        14,
        24,
        MediaQuery.of(context).viewPadding.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle Pill
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Animated Hero Checkmark Badge
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.40),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title & Subtitle
          Text(
            'Presensi Berhasil Dicatat!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Kehadiran Anda telah terverifikasi secara akurat.',
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Structured Receipt Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceSecondaryColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                // Event Type Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: eventColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            eventIcon,
                            size: 16,
                            color: eventColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          res.action.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),

                    // Status Badge (Tepat Waktu / Dalam Radius)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: res.isWithinRadius
                            ? (isDark
                                ? const Color(0xFF064E3B).withValues(alpha: 0.5)
                                : const Color(0xFFDCFCE7))
                            : (isDark
                                ? const Color(0xFF4C1D24).withValues(alpha: 0.5)
                                : const Color(0xFFFFF1F2)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: res.isWithinRadius
                              ? (isDark
                                  ? const Color(0xFF047857).withValues(alpha: 0.4)
                                  : const Color(0xFFBBF7D0))
                              : (isDark
                                  ? const Color(0xFF7F1D1D)
                                  : const Color(0xFFFFCDD2)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            res.isWithinRadius
                                ? Icons.verified_rounded
                                : Icons.warning_amber_rounded,
                            size: 12,
                            color: res.isWithinRadius
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFE11D48),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            res.isWithinRadius ? 'Dalam Radius' : 'Luar Radius',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: res.isWithinRadius
                                  ? (isDark
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFF15803D))
                                  : (isDark
                                      ? const Color(0xFFF87171)
                                      : const Color(0xFFE11D48)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                const SizedBox(height: 12),

                // Recorded Time & Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WAKTU TERCATAT',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                            color: context.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _formatTimeWithWib(res.timestamp),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimaryColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatIndoFullDate(res.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                const SizedBox(height: 12),

                // Location Details Row
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        res.locationName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${res.distance.round()} m dari kantor',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Auto-dismiss linear countdown bar
          AnimatedBuilder(
            animation: _countdownController,
            builder: (context, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: _countdownController.value,
                  minHeight: 2.5,
                  backgroundColor: Colors.transparent,
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          // Primary Done Button
          SizedBox(
            width: double.infinity,
            child: BouncingButton(
              scaleDown: 0.96,
              onPressed: _dismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Selesai',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
