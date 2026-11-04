import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/auto_oriented_image.dart';
import '../../../data/models/attendance_event_model.dart';
import 'photo_preview_dialog.dart';

class TimingColumn extends StatelessWidget {
  final String label;
  final String scheduledTime;
  final String? actualTime;
  final AttendanceEvent? event;
  final IconData fallbackIcon;
  final bool isCompleted;
  final bool isLate;

  const TimingColumn({
    super.key,
    required this.label,
    required this.scheduledTime,
    required this.actualTime,
    required this.event,
    required this.fallbackIcon,
    required this.isCompleted,
    this.isLate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular selfie avatar (tappable to view full photo)
          if (event?.fullSelfieUrl != null && event!.fullSelfieUrl!.isNotEmpty)
            GestureDetector(
              onTap: () => PhotoPreviewDialog.show(
                context,
                imageUrl: event!.fullSelfieUrl!,
                title: 'Foto Presensi: $label',
                subtitle: actualTime != null ? 'Waktu: $actualTime' : null,
              ),
              child: Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: AutoOrientedImage(
                        imageUrl: event!.fullSelfieUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          color: const Color(0xFFFFF1F2),
                          child: Icon(
                            fallbackIcon,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        size: 9,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFE4E6), width: 1.5),
              ),
              child: Icon(fallbackIcon, color: AppColors.primary, size: 20),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    text: label,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textSecondaryColor,
                      fontWeight: FontWeight.normal,
                    ),
                    children: [
                      TextSpan(
                        text: ' ($scheduledTime)',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actualTime ?? '--:--',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    if (isCompleted && actualTime != null) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.check_circle_rounded,
                        size: 15,
                        color: isLate
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

