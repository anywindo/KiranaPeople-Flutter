import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/auto_oriented_image.dart';
import '../../../../data/models/attendance_event_model.dart';
import '../../../attendance/widgets/photo_preview_dialog.dart';

class HistoryLocationHeader extends StatelessWidget {
  final AttendanceEvent event;
  final double lat;
  final double lng;
  final bool hasPhoto;
  final int selectedTab;
  final ValueChanged<int>? onTabChanged;
  final bool showTabs;

  const HistoryLocationHeader({
    super.key,
    required this.event,
    required this.lat,
    required this.lng,
    required this.hasPhoto,
    this.selectedTab = 0,
    this.onTabChanged,
    this.showTabs = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (hasPhoto)
              GestureDetector(
                onTap: () => PhotoPreviewDialog.show(
                  context,
                  imageUrl: event.fullSelfieUrl!,
                  title: 'Foto Presensi: ${event.eventType.label}',
                  subtitle:
                      'Koordinat: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                ),
                child: Stack(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: ClipOval(
                        child: AutoOrientedImage(
                          imageUrl: event.fullSelfieUrl!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorWidget: const Icon(
                            Icons.person_rounded,
                            color: AppColors.primary,
                            size: 20,
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
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Titik Presensi: ${event.eventType.label}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Koordinat: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
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
        if (showTabs && hasPhoto && onTabChanged != null) ...[
          const SizedBox(height: 14),
          Container(
            height: 38,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: context.surfaceSecondaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => onTabChanged!(0),
                    borderRadius: BorderRadius.circular(9),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selectedTab == 0
                            ? context.surfaceColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: selectedTab == 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_rounded,
                            size: 15,
                            color: selectedTab == 0
                                ? AppColors.primary
                                : context.textSecondaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Peta Lokasi (2 Pin)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: selectedTab == 0
                                  ? AppColors.primary
                                  : context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => onTabChanged!(1),
                    borderRadius: BorderRadius.circular(9),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selectedTab == 1
                            ? context.surfaceColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: selectedTab == 1
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            size: 15,
                            color: selectedTab == 1
                                ? AppColors.primary
                                : context.textSecondaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Foto Selfie',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: selectedTab == 1
                                  ? AppColors.primary
                                  : context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
