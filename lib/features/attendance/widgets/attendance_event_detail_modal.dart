import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/attendance_event_model.dart';
import '../../../data/models/work_location_model.dart';
import '../../history/widgets/location/history_location_header.dart';
import '../../history/widgets/location/history_location_map_view.dart';
import '../../history/widgets/location/history_location_photo_view.dart';
import '../../history/widgets/location/history_location_radius_badge.dart';

class AttendanceEventDetailModal extends StatelessWidget {
  final AttendanceEvent event;
  final WorkLocation? workLocation;

  const AttendanceEventDetailModal({
    super.key,
    required this.event,
    this.workLocation,
  });

  static Future<void> show(
    BuildContext context, {
    required AttendanceEvent event,
    WorkLocation? workLocation,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          AttendanceEventDetailModal(event: event, workLocation: workLocation),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lat = event.latitude ?? -7.025648;
    final lng = event.longitude ?? 109.957296;
    final userLatLng = LatLng(lat, lng);

    final resolvedWorkLocation = workLocation;
    final officeLatLng = resolvedWorkLocation != null
        ? LatLng(resolvedWorkLocation.latitude, resolvedWorkLocation.longitude)
        : const LatLng(-7.025801, 109.956894);

    final officeName =
        (resolvedWorkLocation?.name != null &&
            resolvedWorkLocation!.name.isNotEmpty)
        ? resolvedWorkLocation.name
        : 'Kantor Utama (Tersono, Batang)';

    final radius = resolvedWorkLocation?.radius ?? 50.0;

    final distance = Geolocator.distanceBetween(
      userLatLng.latitude,
      userLatLng.longitude,
      officeLatLng.latitude,
      officeLatLng.longitude,
    );
    final isInside = distance <= radius;
    final hasPhoto =
        event.fullSelfieUrl != null && event.fullSelfieUrl!.isNotEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            HistoryLocationHeader(
              event: event,
              lat: lat,
              lng: lng,
              hasPhoto: hasPhoto,
              showTabs: false,
            ),
            const SizedBox(height: 14),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Foto Selfie Presensi (Di atas)
                    if (hasPhoto) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Foto Selfie Presensi',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      HistoryLocationPhotoView(
                        event: event,
                        lat: lat,
                        lng: lng,
                      ),
                      const SizedBox(height: 18),
                    ],

                    // 2. Peta Lokasi Presensi (2 Pin + Radius)
                    Row(
                      children: [
                        const Icon(
                          Icons.map_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Peta Lokasi Presensi',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    HistoryLocationMapView(
                      userLatLng: userLatLng,
                      officeLatLng: officeLatLng,
                      officeName: officeName,
                      radius: radius,
                    ),
                    const SizedBox(height: 10),
                    HistoryLocationRadiusBadge(
                      isInside: isInside,
                      distance: distance,
                      radius: radius,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Tutup',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
