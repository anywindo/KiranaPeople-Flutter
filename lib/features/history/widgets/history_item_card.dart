import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/auto_oriented_image.dart';
import '../../../core/widgets/bouncing_button.dart';
import '../../../data/models/attendance_event_model.dart';
import '../../../data/models/attendance_model.dart';

class HistoryItemCard extends StatelessWidget {
  final AttendanceRecord item;
  final void Function(AttendanceEvent event) onEventTap;

  const HistoryItemCard({
    super.key,
    required this.item,
    required this.onEventTap,
  });

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

  static String formatShortTime(String timeStr) {
    final dt = DateTime.tryParse(timeStr);
    if (dt != null) {
      final local = dt.isUtc ? dt.toLocal() : dt;
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
    if (timeStr.contains(' ')) {
      final parts = timeStr.split(' ');
      if (parts.length > 1 && parts[1].length >= 5) {
        return parts[1].substring(0, 5);
      }
    }
    if (timeStr.length >= 5) {
      return timeStr.substring(0, 5);
    }
    return timeStr;
  }

  static IconData getEventIcon(AttendanceEventType type) {
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

  @override
  Widget build(BuildContext context) {
    final isLate = item.isLate;
    final rawStatus = item.status ?? (isLate ? 'LATE' : 'Tepat Waktu');

    String displayStatus = isLate ? 'Terlambat' : 'Tepat Waktu';
    if (!isLate &&
        (rawStatus.toUpperCase() == 'EARLY' ||
            rawStatus.toLowerCase().contains('awal'))) {
      displayStatus = 'Lebih Awal';
    }
    final shiftName = item.shift?.name ?? 'OFFICE';
    final formattedDate = formatIndoDateString(item.date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header: Date + Badges
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
            Row(
              children: [
                // Status Badge (Terlambat)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isLate
                        ? (context.isDarkMode
                            ? const Color(0xFF3B151E)
                            : const Color(0xFFFFF1F2))
                        : (context.isDarkMode
                            ? const Color(0xFF064E3B).withValues(alpha: 0.5)
                            : const Color(0xFFDCFCE7)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isLate
                          ? (context.isDarkMode
                              ? const Color(0xFF4C1D24)
                              : const Color(0xFFFFE4E6))
                          : (context.isDarkMode
                              ? const Color(0xFF047857).withValues(alpha: 0.4)
                              : const Color(0xFFBBF7D0)),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    displayStatus,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isLate
                          ? const Color(0xFFEF4444)
                          : (context.isDarkMode
                              ? const Color(0xFF34D399)
                              : const Color(0xFF15803D)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Shift Badge (OFFICE)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: context.surfaceSecondaryColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: context.isDarkMode
                          ? const Color(0xFF334155)
                          : const Color(0xFFCBD5E1),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    shiftName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Event Cards for that date
        ...item.events.map((event) {
          final timeStr = formatShortTime(event.timestamp);

          return BouncingButton(
            scaleDown: 0.98,
            hapticType: BouncingHapticType.light,
            onPressed: () => onEventTap(event),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.isDarkMode
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: context.isDarkMode ? 0.35 : 0.08,
                    ),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: context.isDarkMode ? 0.18 : 0.03,
                    ),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // Circular Selfie Avatar or Event Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.borderColor,
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child:
                            (event.fullSelfieUrl != null &&
                                event.fullSelfieUrl!.isNotEmpty)
                            ? AutoOrientedImage(
                                imageUrl: event.fullSelfieUrl!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorWidget: Container(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  child: Icon(
                                    getEventIcon(event.eventType),
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                              )
                            : Container(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                child: Icon(
                                  getEventIcon(event.eventType),
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Event Title & Time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.eventType.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 13,
                                color: context.textSecondaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.textSecondaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (event.latitude != null &&
                                  event.longitude != null) ...[
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Subtle Chevron Icon
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: context.surfaceSecondaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.isDarkMode
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: context.textMutedColor,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
