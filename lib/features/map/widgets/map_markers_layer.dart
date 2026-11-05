import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/work_location_model.dart';

class MapMarkersLayer extends StatelessWidget {
  final WorkLocation? workLocation;
  final LatLng officeLatLng;
  final String officeName;
  final double radius;
  final LatLng? userLatLng;

  const MapMarkersLayer({
    super.key,
    required this.workLocation,
    required this.officeLatLng,
    required this.officeName,
    required this.radius,
    this.userLatLng,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Stack(
      children: [
        // Geofence Circle (Emerald border + translucent green fill)
        if (workLocation != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: officeLatLng,
                radius: radius,
                useRadiusInMeter: true,
                color: const Color(0xFF10B981)
                    .withValues(alpha: isDark ? 0.22 : 0.18),
                borderColor: const Color(0xFF10B981),
                borderStrokeWidth: 2.0,
              ),
            ],
          ),

        // Marker Layer
        MarkerLayer(
          markers: [
            // 1. Office Pin & Bubble
            if (workLocation != null)
              Marker(
                point: officeLatLng,
                width: 220,
                height: 80,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.apartment_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? context.borderColor
                              : Colors.transparent,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.35 : 0.12,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        officeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 2. User Pin & "Posisi Anda" pill
            if (userLatLng != null)
              Marker(
                point: userLatLng!,
                width: 120,
                height: 76,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Posisi Anda',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_walk_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
