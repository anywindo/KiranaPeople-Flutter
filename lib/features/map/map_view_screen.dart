import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/location_helper.dart';
import '../../data/models/attendance_event_model.dart';
import '../../providers/attendance_provider.dart';
import '../attendance/camera_selfie_view.dart';
import '../attendance/shift_picker_sheet.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  const MapViewScreen({super.key});

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      final pos = await LocationHelper.determinePosition();
      if (!mounted) return;
      setState(() {
        _currentPosition = pos;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatShortTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '--:--';
    if (timeStr.length >= 5) {
      return timeStr.substring(0, 5);
    }
    return timeStr;
  }

  AttendanceEventType _resolveTargetAction(List<AttendanceEvent> events) {
    final hasStartShift =
        events.any((e) => e.eventType == AttendanceEventType.startShift);
    final hasStartBreak =
        events.any((e) => e.eventType == AttendanceEventType.startBreak);
    final hasEndBreak =
        events.any((e) => e.eventType == AttendanceEventType.endBreak);
    final hasEndShift =
        events.any((e) => e.eventType == AttendanceEventType.endShift);

    if (!hasStartShift) {
      return AttendanceEventType.startShift;
    }
    if (!hasStartBreak) {
      return AttendanceEventType.startBreak;
    }
    if (!hasEndBreak) {
      return AttendanceEventType.endBreak;
    }
    if (!hasEndShift) {
      return AttendanceEventType.endShift;
    }
    return AttendanceEventType.startShift;
  }

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(todayAttendanceProvider);
    final todayData = attendanceState.data.value;
    final workLocation = todayData?.workLocation;
    final events = todayData?.events ?? [];

    final selectedShift = attendanceState.selectedShift ??
        todayData?.shift ??
        (todayData?.availableShifts?.isNotEmpty == true
            ? todayData!.availableShifts!.first
            : null);

    final userLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(-6.9897, 109.8765); // Fallback Batang / Central Java

    final officeLatLng = workLocation != null
        ? LatLng(workLocation.latitude, workLocation.longitude)
        : userLatLng;

    final radius = workLocation?.radius ?? 100.0;
    final officeName = workLocation?.name ?? 'Kantor Utama (Tersono, Batang)';

    final double distance = _currentPosition != null && workLocation != null
        ? Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            workLocation.latitude,
            workLocation.longitude,
          )
        : 0.0;

    final bool isInside = distance <= radius;

    final hasStartedShift =
        events.any((e) => e.eventType == AttendanceEventType.startShift);
    final hasEndedShift =
        events.any((e) => e.eventType == AttendanceEventType.endShift) ||
            todayData?.status?.toUpperCase() == 'COMPLETED' ||
            todayData?.status?.toUpperCase() == 'SELESAI';
    final hasStartedBreak =
        events.any((e) => e.eventType == AttendanceEventType.startBreak);
    final hasEndedBreak =
        events.any((e) => e.eventType == AttendanceEventType.endBreak);
    final isOnBreak = hasStartedBreak && !hasEndedBreak;

    final targetAction = _resolveTargetAction(events);

    String actionBtnLabel = 'Ambil Presensi: Masuk Kerja';
    if (!hasStartedShift) {
      actionBtnLabel = 'Ambil Presensi: Masuk Kerja';
    } else if (!hasStartedBreak) {
      actionBtnLabel = 'Ambil Presensi: Mulai Istirahat';
    } else if (isOnBreak) {
      actionBtnLabel = 'Ambil Presensi: Selesai Istirahat';
    } else if (!hasEndedShift) {
      actionBtnLabel = 'Ambil Presensi: Pulang Kerja';
    } else {
      actionBtnLabel = 'Presensi Hari Ini Selesai';
    }

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Stack(
              children: [
                // Fullscreen OpenStreetMap
                Positioned.fill(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter:
                          workLocation != null ? officeLatLng : userLatLng,
                      initialZoom: 16.5,
                      maxZoom: 19.0,
                      minZoom: 10.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'com.kiranadesainindonesia.kiranapeople',
                      ),

                      // Office Geofence Circle (Emerald border + translucent green fill)
                      if (workLocation != null)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: officeLatLng,
                              radius: radius,
                              useRadiusInMeter: true,
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.18),
                              borderColor: const Color(0xFF10B981),
                              borderStrokeWidth: 2.0,
                            ),
                          ],
                        ),

                      // Marker Layer (Office Pin & User Pin)
                      MarkerLayer(
                        markers: [
                          // 1. Office Pin (Matches Screenshot 1)
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
                                      border: Border.all(
                                          color: Colors.white, width: 2),
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
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      officeName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // 2. User Pin (Matches Screenshot 1 with "Posisi Anda" badge)
                          if (_currentPosition != null)
                            Marker(
                              point: userLatLng,
                              width: 120,
                              height: 76,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // "Posisi Anda" pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
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
                                  // Blue circular marker
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF007AFF),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
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
                  ),
                ),

                // Top Floating Pill Bar (Matches Screenshot 1)
                Positioned(
                  top: topPadding + 10,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.apartment_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            officeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            _fetchLocation();
                            ref.read(todayAttendanceProvider.notifier).refresh();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.refresh_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right Floating Map Controls (Matches Screenshot 1)
                Positioned(
                  right: 16,
                  bottom: 215,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.near_me_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          onPressed: () {
                            if (_currentPosition != null) {
                              _mapController.move(userLatLng, 17.5);
                            } else {
                              _fetchLocation();
                            }
                          },
                        ),
                        Container(
                          width: 24,
                          height: 1,
                          color: const Color(0xFFF2F2F7),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.zoom_out_map_rounded,
                            color: Color(0xFF1F2937),
                            size: 18,
                          ),
                          onPressed: () {
                            if (_currentPosition != null && workLocation != null) {
                              final bounds = LatLngBounds.fromPoints(
                                  [userLatLng, officeLatLng]);
                              _mapController.fitCamera(
                                CameraFit.bounds(
                                  bounds: bounds,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 60, vertical: 120),
                                ),
                              );
                            } else {
                              _mapController.move(officeLatLng, 16.5);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Floating Sheet Card (Matches Screenshot 1)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Row 1: Radius Indicator + Rute Button
                        Row(
                          children: [
                            // Pulsing green dot
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: isInside
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isInside
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEF4444))
                                        .withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isInside
                                        ? 'Dalam Radius Presensi'
                                        : 'Di Luar Radius Presensi',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isInside
                                          ? const Color(0xFF059669)
                                          : const Color(0xFFEF4444),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${distance.round()} m dari titik kantor',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () async {
                                final uri = Uri.parse(
                                    'https://www.google.com/maps/dir/?api=1&destination=${officeLatLng.latitude},${officeLatLng.longitude}');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.directions_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Rute',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Row 2: Shift Information Container
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF2F2F7)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time_filled_rounded,
                                size: 16,
                                color: Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedShift != null
                                      ? 'Shift: ${selectedShift.name} [${_formatShortTime(selectedShift.startTime)} - ${_formatShortTime(selectedShift.endTime)}]'
                                      : 'Shift: OFFICE [08:00 - 16:00]',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                              if (!hasStartedShift &&
                                  todayData?.availableShifts?.isNotEmpty == true)
                                InkWell(
                                  onTap: () {
                                    ShiftPickerSheet.show(
                                      context,
                                      shifts: todayData!.availableShifts!,
                                      selectedShift: selectedShift,
                                      onShiftSelected: (s) {
                                        ref
                                            .read(todayAttendanceProvider
                                                .notifier)
                                            .selectShift(s);
                                      },
                                    );
                                  },
                                  child: const Text(
                                    'Ganti Shift',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Row 3: Big Hot Pink Action Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor:
                                  AppColors.primary.withValues(alpha: 0.35),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: hasEndedShift
                                ? null
                                : () async {
                                    final res = await CameraSelfieView.push(
                                      context,
                                      action: targetAction,
                                      shiftId: selectedShift?.id,
                                      workLocation: workLocation,
                                    );
                                    if (res == true) {
                                      ref
                                          .read(
                                              todayAttendanceProvider.notifier)
                                          .refresh();
                                    }
                                  },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 19,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  actionBtnLabel,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
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
