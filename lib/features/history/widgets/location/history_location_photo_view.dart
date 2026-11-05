import 'package:flutter/material.dart';

import '../../../../core/widgets/auto_oriented_image.dart';
import '../../../../data/models/attendance_event_model.dart';
import '../../../attendance/widgets/photo_preview_dialog.dart';

class HistoryLocationPhotoView extends StatelessWidget {
  final AttendanceEvent event;
  final double lat;
  final double lng;

  const HistoryLocationPhotoView({
    super.key,
    required this.event,
    required this.lat,
    required this.lng,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = event.fullSelfieUrl;
    if (photoUrl == null || photoUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => PhotoPreviewDialog.show(
        context,
        imageUrl: photoUrl,
        title: 'Foto Presensi: ${event.eventType.label}',
        subtitle:
            'Koordinat: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 280,
              width: double.infinity,
              color: const Color(0xFF0F172A),
              child: AutoOrientedImage(imageUrl: photoUrl, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Perbesar Foto',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
