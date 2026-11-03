import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/location_helper.dart';
import '../../data/models/attendance_event_model.dart';
import '../../data/models/shift_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/history_provider.dart';
import '../attendance/camera_selfie_view.dart';
import 'widgets/map_attendance_action_card.dart';
import 'widgets/map_controls_overlay.dart';
import 'widgets/map_markers_layer.dart';
import 'widgets/map_top_location_pill.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  const MapViewScreen({super.key});

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  String? _locationError;
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation({bool isManualRefresh = false}) async {
    setState(() {
      _locationError = null;
      if (isManualRefresh) {
        _isRefreshing = true;
      }
    });

    try {
      final pos = await LocationHelper.determinePosition();
      if (!mounted) return;
      setState(() {
        _currentPosition = pos;
        _isLoading = false;
        _isRefreshing = false;
        _locationError = null;
      });
    } catch (e) {
      if (!mounted) return;
      final cleanErr = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _currentPosition = null;
        _isLoading = false;
        _isRefreshing = false;
        _locationError = cleanErr;
      });
    }
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

  void _recenterOnUser(LatLng userLatLng) {
    if (_currentPosition != null) {
      _mapController.move(userLatLng, 17.5);
    } else {
      _fetchLocation(isManualRefresh: true);
    }
  }

  void _fitAllBounds(LatLng userLatLng, LatLng officeLatLng) {
    if (_currentPosition != null) {
      final bounds = LatLngBounds.fromPoints([userLatLng, officeLatLng]);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 120),
        ),
      );
    } else {
      _mapController.move(officeLatLng, 16.5);
    }
  }

  Future<void> _handleTakeAttendance({
    required AttendanceEventType targetAction,
    required Shift? selectedShift,
    required dynamic workLocation,
  }) async {
    final res = await CameraSelfieView.push(
      context,
      action: targetAction,
      shiftId: selectedShift?.id,
      workLocation: workLocation,
    );
    if (res == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${targetAction.label} berhasil dicatat!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      ref.read(todayAttendanceProvider.notifier).refresh();
      ref.read(historyProvider.notifier).refresh();
    }
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

    final bool isInside = _currentPosition != null && distance <= radius;

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

    final isBeforeBreak = Shift.isBeforeBreakTime(selectedShift);
    final isBreakActionDisabled =
        hasStartedShift && !hasStartedBreak && isBeforeBreak;

    final targetAction = _resolveTargetAction(events);

    String actionBtnLabel = 'Ambil Presensi: Masuk Kerja';
    if (!hasStartedShift) {
      actionBtnLabel = 'Ambil Presensi: Masuk Kerja';
    } else if (!hasStartedBreak) {
      actionBtnLabel = isBreakActionDisabled
          ? 'Belum Waktunya Istirahat'
          : 'Ambil Presensi: Mulai Istirahat';
    } else if (isOnBreak) {
      actionBtnLabel = 'Ambil Presensi: Selesai Istirahat';
    } else if (!hasEndedShift) {
      actionBtnLabel = 'Ambil Presensi: Pulang Kerja';
    } else {
      actionBtnLabel = 'Presensi Hari Ini Selesai';
    }

    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Stack(
              children: [
                // 1. Fullscreen OpenStreetMap with Dark Mode CartoDB Tile support
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
                        tileBuilder: isDark
                            ? (context, tileWidget, tile) {
                                return ColorFiltered(
                                  colorFilter: const ColorFilter.matrix(<double>[
                                    -0.75, 0, 0, 0, 215,
                                    0, -0.75, 0, 0, 215,
                                    0, 0, -0.70, 0, 225,
                                    0, 0, 0, 1, 0,
                                  ]),
                                  child: tileWidget,
                                );
                              }
                            : null,
                      ),

                      // Geofence Circle & Pins Layer
                      MapMarkersLayer(
                        workLocation: workLocation,
                        officeLatLng: officeLatLng,
                        officeName: officeName,
                        radius: radius,
                        userLatLng: _currentPosition != null ? userLatLng : null,
                      ),
                    ],
                  ),
                ),

                // 2. Top Floating Location Pill
                MapTopLocationPill(
                  officeName: officeName,
                  topPadding: topPadding,
                  isRefreshing: _isRefreshing,
                  onRefresh: () {
                    _fetchLocation(isManualRefresh: true);
                    ref.read(todayAttendanceProvider.notifier).refresh();
                  },
                ),

                // 3. Bottom Floating Sheet Card + Right Map Controls
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Right Floating Map Controls
                      MapControlsOverlay(
                        onRecenter: () => _recenterOnUser(userLatLng),
                        onFitBounds: () => _fitAllBounds(userLatLng, officeLatLng),
                      ),

                      // Bottom Floating Attendance Action Card
                      MapAttendanceActionCard(
                        hasLocation: _currentPosition != null,
                        locationError: _locationError,
                        isInsideRadius: isInside,
                        distance: distance,
                        officeLatLng: officeLatLng,
                        officeName: officeName,
                        selectedShift: selectedShift,
                        isActionDisabled:
                            hasEndedShift || isBreakActionDisabled,
                        actionBtnLabel: actionBtnLabel,
                        onAction: () => _handleTakeAttendance(
                          targetAction: targetAction,
                          selectedShift: selectedShift,
                          workLocation: workLocation,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
