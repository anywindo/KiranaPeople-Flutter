import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/auto_oriented_image.dart';
import '../../../data/models/attendance_event_model.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/shift_model.dart';

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
    // Find start shift event if present to validate shift start timing
    AttendanceEvent? startShiftEvent;
    for (final e in item.events) {
      if (e.eventType == AttendanceEventType.startShift) {
        startShiftEvent = e;
        break;
      }
    }
    String? checkInTime;
    if (startShiftEvent != null) {
      final dt = DateTime.tryParse(startShiftEvent.timestamp);
      final localDt = dt != null ? (dt.isUtc ? dt.toLocal() : dt) : null;
      checkInTime = localDt != null
          ? '${localDt.hour.toString().padLeft(2, '0')}:${localDt.minute.toString().padLeft(2, '0')}'
          : formatShortTime(startShiftEvent.timestamp);
    }

    final isShiftStartLate = Shift.isShiftStartLate(
      actualTime: checkInTime,
      scheduledTime: item.shift?.startTime ?? '08:00',
      ruleEnabled: item.shift?.attendanceRuleEnabled ?? true,
      ruleMinutes: item.shift?.attendanceRuleMinutes ?? 15,
    );

    final rawStatus =
        item.status ?? (isShiftStartLate ? 'LATE' : 'Tepat Waktu');
    final isLate = rawStatus.toUpperCase() == 'LATE' ||
        rawStatus.toLowerCase().contains('terlambat') ||
        (startShiftEvent != null && isShiftStartLate);

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
                        ? const Color(0xFFFFF1F2)
                        : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    displayStatus,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isLate
                          ? const Color(0xFFE11D48)
                          : const Color(0xFF15803D),
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

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => onEventTap(event),
                borderRadius: BorderRadius.circular(16),
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
                          child: (event.fullSelfieUrl != null &&
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
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: context.borderColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 12,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Lokasi GPS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: context.textMutedColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
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
                            color: context.borderColor,
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
            ),
          );
        }),
      ],
    );
  }
}
