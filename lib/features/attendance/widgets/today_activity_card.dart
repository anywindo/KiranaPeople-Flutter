import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/auto_oriented_image.dart';
import '../../../core/widgets/bouncing_button.dart';
import '../../../data/models/attendance_event_model.dart';

class TodayActivityCard extends StatelessWidget {
  final List<AttendanceEvent> events;
  final VoidCallback onViewFullHistory;
  final ValueChanged<AttendanceEvent> onEventTap;

  const TodayActivityCard({
    super.key,
    required this.events,
    required this.onViewFullHistory,
    required this.onEventTap,
  });

  String _formatIndoFullDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.isDarkMode
              ? const Color(0xFF334155)
              : const Color(0xFFCBD5E1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.40 : 0.08,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.25 : 0.04,
            ),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aktivitas Hari Ini',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              BouncingButton(
                scaleDown: 0.94,
                hapticType: BouncingHapticType.light,
                onPressed: onViewFullHistory,
                child: const Row(
                  children: [
                    Text(
                      'Riwayat Lengkap',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Events or Empty placeholder
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.surfaceSecondaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.access_time_filled_rounded,
                      color: Color(0xFFC7C7CC),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Belum ada riwayat presensi hari ini.',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              separatorBuilder: (_, _) => Divider(
                height: 20,
                thickness: 0.8,
                color: context.dividerColor,
              ),
              itemBuilder: (context, index) {
                // Sort newest first
                final reversedList = events.reversed.toList();
                final event = reversedList[index];
                final dt = DateTime.tryParse(event.timestamp);
                final localDt = dt != null
                    ? (dt.isUtc ? dt.toLocal() : dt)
                    : null;
                final formattedTime = localDt != null
                    ? '${localDt.hour.toString().padLeft(2, '0')}:${localDt.minute.toString().padLeft(2, '0')}'
                    : event.timestamp;
                final formattedDate = localDt != null
                    ? _formatIndoFullDate(localDt)
                    : 'Hari Ini';

                return BouncingButton(
                  scaleDown: 0.98,
                  hapticType: BouncingHapticType.light,
                  onPressed: () => onEventTap(event),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 2,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Circular Selfie or Fallback
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
                                        _getEventIcon(event.eventType),
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
                                      _getEventIcon(event.eventType),
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.eventType.label,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.textSecondaryColor,
                                    ),
                                  ),
                                  if (event.latitude != null &&
                                      event.longitude != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 3,
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: context.borderColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // Jelek
                                    // const Icon(
                                    //   Icons.location_on_rounded,
                                    //   size: 11,
                                    //   color: Color(0xFF94A3B8),
                                    // ),
                                    // const SizedBox(width: 2),
                                    // Text(
                                    //   'Lokasi GPS',
                                    //   style: TextStyle(
                                    //     fontSize: 11,
                                    //     color: context.textMutedColor,
                                    //     fontWeight: FontWeight.w500,
                                    //   ),
                                    // ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formattedTime,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: context.textMutedColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
