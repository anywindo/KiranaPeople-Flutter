import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/location_helper.dart';
import '../../data/models/attendance_event_model.dart';
import '../../data/models/work_location_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import 'attendance_map_modal.dart';

class AttendanceConfirmationView extends ConsumerStatefulWidget {
  final File photoFile;
  final AttendanceEventType action;
  final int? shiftId;
  final WorkLocation? workLocation;
  final VoidCallback onRetake;
  final VoidCallback onSubmittedSuccess;

  const AttendanceConfirmationView({
    super.key,
    required this.photoFile,
    required this.action,
    this.shiftId,
    this.workLocation,
    required this.onRetake,
    required this.onSubmittedSuccess,
  });

  @override
  ConsumerState<AttendanceConfirmationView> createState() =>
      _AttendanceConfirmationViewState();
}

class _AttendanceConfirmationViewState
    extends ConsumerState<AttendanceConfirmationView> {
  Position? _currentPosition;
  String? _locationError;
  bool _isWithinRadius = false;
  bool _isLoadingLocation = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final pos = await LocationHelper.determinePosition();
      if (!mounted) return;

      double dist = 0.0;
      bool within = true;

      if (widget.workLocation != null) {
        dist = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          widget.workLocation!.latitude,
          widget.workLocation!.longitude,
        );
        within = dist <= widget.workLocation!.radius;
      }

      setState(() {
        _currentPosition = pos;
        _isWithinRadius = within;
        _isLoadingLocation = false;
        _locationError = null;
      });
    } catch (e) {
      if (!mounted) return;
      final cleanErr = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _currentPosition = null;
        _isWithinRadius = false;
        _isLoadingLocation = false;
        _locationError = cleanErr;
      });
    }
  }

  Future<void> _submitAttendance() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    if (_currentPosition == null) {
      await _fetchLocation();
      if (!mounted) return;
      if (_currentPosition == null) {
        setState(() {
          _isSubmitting = false;
        });
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Lokasi GPS Tidak Ditemukan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              _locationError ??
                  'Gagal mendapatkan lokasi GPS. Pastikan GPS dan izin lokasi telah diaktifkan.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
        return;
      }
    }

    if (widget.workLocation != null && !_isWithinRadius) {
      setState(() {
        _isSubmitting = false;
      });
      final dist = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        widget.workLocation!.latitude,
        widget.workLocation!.longitude,
      );
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Di Luar Radius Kantor',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Anda berada di luar radius kantor (${dist.round()}m dari batas yang diizinkan ${widget.workLocation!.radius.round()}m). Anda harus berada di area kantor untuk melakukan presensi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      return;
    }

    final success = await ref
        .read(todayAttendanceProvider.notifier)
        .submitEvent(
          eventType: widget.action,
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          accuracy: _currentPosition!.accuracy,
          altitude: _currentPosition!.altitude,
          deviceTimestamp: _currentPosition!.timestamp,
          isMocked: _currentPosition!.isMocked,
          photoFile: widget.photoFile,
          shiftId: widget.shiftId,
        );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      // Purge local selfie cache file upon successful server reception (GDPR / Data Minimization)
      try {
        if (await widget.photoFile.exists()) {
          await widget.photoFile.delete();
        }
      } catch (_) {}
      widget.onSubmittedSuccess();
    } else {
      final error =
          ref.read(todayAttendanceProvider).submitError ??
          'Gagal mencatat presensi.';
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Presensi Gagal',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(error),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    }
  }

  void _openMap() {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _locationError ??
                'Lokasi GPS belum tersedia. Menghubungkan ulang...',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      _fetchLocation();
      return;
    }
    AttendanceMapModal.show(
      context,
      userLatitude: _currentPosition!.latitude,
      userLongitude: _currentPosition!.longitude,
      accuracy: _currentPosition!.accuracy,
      workLocation: widget.workLocation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final now = DateTime.now();
    final formattedTime =
        '${now.day} ${_monthName(now.month)} ${now.year} • ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';

    final accuracyMeters = _currentPosition != null
        ? _currentPosition!.accuracy.round()
        : 6;

    final locationName =
        widget.workLocation?.name ?? 'Kantor Utama (Tersono, Batang)';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  InkWell(
                    onTap: widget.onRetake,
                    borderRadius: BorderRadius.circular(16),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 2),
                          Text(
                            'Foto',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Center Action Title
                  Text(
                    widget.action.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Batal button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Captured Photo Area with Badges & Overlays
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Photo Image
                      Image.file(widget.photoFile, fit: BoxFit.cover),

                      // Top Badges (Radius & Peta)
                      Positioned(
                        top: 14,
                        left: 14,
                        right: 14,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Geofence status pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _currentPosition == null
                                          ? const Color(0xFFF59E0B)
                                          : (_isWithinRadius
                                                ? AppColors.success
                                                : AppColors.error),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isLoadingLocation
                                        ? 'Mencari GPS...'
                                        : (_currentPosition == null
                                              ? (_locationError ??
                                                    'GPS Tidak Aktif')
                                              : 'Akurasi ${accuracyMeters}m • ${_isWithinRadius ? 'Dalam Radius' : 'Diluar Radius'}'),
                                    style: TextStyle(
                                      color: _currentPosition == null
                                          ? const Color(0xFFFBBF24)
                                          : (_isWithinRadius
                                                ? const Color(0xFF4ADE80)
                                                : const Color(0xFFF87171)),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Peta Pill Button
                            InkWell(
                              onTap: _openMap,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.map_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Peta',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom Overlay Gradient + Employee & Office info
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.85),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // User Name + Date/Time
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      user?.name ?? 'User Testing',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      formattedTime,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Office Location Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.60),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.20),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.apartment_rounded,
                                      color: Colors.white,
                                      size: 15,
                                    ),
                                    const SizedBox(width: 6),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 140,
                                      ),
                                      child: Text(
                                        locationName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
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
            ),

            const SizedBox(height: 16),

            // Bottom Action Controls (Ambil Ulang & Simpan Presensi)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  // Ambil Ulang
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFF27272A),
                          foregroundColor: Colors.white,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : widget.onRetake,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh_rounded, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Ambil Ulang',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Simpan Presensi
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: AppColors.primary.withValues(
                            alpha: 0.50,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _submitAttendance,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Simpan Presensi',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }
}
