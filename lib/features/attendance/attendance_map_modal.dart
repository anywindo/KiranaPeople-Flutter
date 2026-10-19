import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/work_location_model.dart';

class AttendanceMapModal extends StatefulWidget {
  final double userLatitude;
  final double userLongitude;
  final double? accuracy;
  final WorkLocation? workLocation;

  const AttendanceMapModal({
    super.key,
    required this.userLatitude,
    required this.userLongitude,
    this.accuracy,
    this.workLocation,
  });

  static Future<void> show(
    BuildContext context, {
    required double userLatitude,
    required double userLongitude,
    double? accuracy,
    WorkLocation? workLocation,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AttendanceMapModal(
        userLatitude: userLatitude,
        userLongitude: userLongitude,
        accuracy: accuracy,
        workLocation: workLocation,
      ),
    );
  }

  @override
  State<AttendanceMapModal> createState() => _AttendanceMapModalState();
}

class _AttendanceMapModalState extends State<AttendanceMapModal> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  LatLng get _userLatLng => LatLng(widget.userLatitude, widget.userLongitude);

  LatLng get _officeLatLng {
    if (widget.workLocation != null) {
      return LatLng(widget.workLocation!.latitude, widget.workLocation!.longitude);
    }
    return _userLatLng;
  }

  double get _radius => widget.workLocation?.radius ?? 100.0;
  String get _officeName => widget.workLocation?.name ?? 'Kantor Utama';

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Stack(
          children: [
            // Flutter Map
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.workLocation != null ? _officeLatLng : _userLatLng,
                initialZoom: 17.5,
                maxZoom: 19.0,
                minZoom: 10.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.kiranadesainindonesia.kiranapeople',
                ),

                // Office Geofence Circle
                if (widget.workLocation != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _officeLatLng,
                        radius: _radius,
                        useRadiusInMeter: true,
                        color: AppColors.primary.withValues(alpha: 0.18),
                        borderColor: AppColors.primary,
                        borderStrokeWidth: 2.0,
                      ),
                    ],
                  ),

                // Markers (Office Pin + User Pin)
                MarkerLayer(
                  markers: [
                    // Office Marker
                    if (widget.workLocation != null)
                      Marker(
                        point: _officeLatLng,
                        width: 180,
                        height: 70,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
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
                                size: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                _officeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // User Location Pin
                    Marker(
                      point: _userLatLng,
                      width: 140,
                      height: 70,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7),
                              borderRadius: BorderRadius.circular(6),
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
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0284C7),
                              shape: BoxShape.circle,
                              boxShadow: [
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
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Top Header Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.70),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 48),
                    const Expanded(
                      child: Text(
                        'Titik Lokasi Presensi',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.40),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.20),
                          ),
                        ),
                        child: const Text(
                          'Tutup',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Floating recenter button
            Positioned(
              bottom: 24,
              right: 16,
              child: FloatingActionButton.small(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1E293B),
                onPressed: () {
                  _mapController.move(_userLatLng, 17.5);
                },
                child: const Icon(Icons.my_location_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
