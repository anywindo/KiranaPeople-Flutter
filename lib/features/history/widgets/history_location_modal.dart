import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/attendance_event_model.dart';
import '../../../data/models/work_location_model.dart';
import 'location/history_location_header.dart';
import 'location/history_location_map_view.dart';
import 'location/history_location_photo_view.dart';
import 'location/history_location_radius_badge.dart';

export 'location/history_location_header.dart';
export 'location/history_location_map_view.dart';
export 'location/history_location_photo_view.dart';
export 'location/history_location_radius_badge.dart';

class HistoryLocationModal extends StatelessWidget {
  final AttendanceEvent event;
  final WorkLocation? workLocation;

  const HistoryLocationModal({
    super.key,
    required this.event,
    this.workLocation,
  });

  static void show(
    BuildContext context, {
    required AttendanceEvent event,
    WorkLocation? workLocation,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          HistoryLocationModal(event: event, workLocation: workLocation),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lat = event.latitude ?? -7.025648;
    final lng = event.longitude ?? 109.957296;
    final userLatLng = LatLng(lat, lng);

    final officeLatLng = workLocation != null
        ? LatLng(workLocation!.latitude, workLocation!.longitude)
        : const LatLng(-7.025801, 109.956894);

    final officeName =
        (workLocation?.name != null && workLocation!.name.isNotEmpty)
        ? workLocation!.name
        : 'Kantor Utama (Tersono, Batang)';

    final radius = workLocation?.radius ?? 50.0;

    final distance = Geolocator.distanceBetween(
      userLatLng.latitude,
      userLatLng.longitude,
      officeLatLng.latitude,
      officeLatLng.longitude,
    );
    final isInside = distance <= radius;
    final hasPhoto =
        event.fullSelfieUrl != null && event.fullSelfieUrl!.isNotEmpty;
    int selectedTab = 0; // 0 = Map, 1 = Foto

    return StatefulBuilder(
      builder: (ctx, setModalState) => Container(
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
                selectedTab: selectedTab,
                onTabChanged: (newTab) =>
                    setModalState(() => selectedTab = newTab),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      if (selectedTab == 1 && hasPhoto)
                        HistoryLocationPhotoView(
                          event: event,
                          lat: lat,
                          lng: lng,
                        )
                      else ...[
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
                      ],
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
                  onPressed: () => Navigator.pop(ctx),
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
      ),
    );
  }
}
