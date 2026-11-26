import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/utils/location_helper.dart';
import '../../core/widgets/offline_banner.dart';
import '../../data/models/attendance_event_model.dart';
import '../../data/models/attendance_submission_result.dart';
import '../../data/models/work_location_model.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import 'attendance_map_modal.dart';
import 'widgets/confirmation/confirmation_action_buttons.dart';
import 'widgets/confirmation/confirmation_app_bar.dart';
import 'widgets/confirmation/confirmation_dialogs.dart';
import 'widgets/confirmation/confirmation_photo_card.dart';

export '../../data/models/attendance_submission_result.dart';
export 'widgets/confirmation/confirmation_action_buttons.dart';
export 'widgets/confirmation/confirmation_app_bar.dart';
export 'widgets/confirmation/confirmation_dialogs.dart';
export 'widgets/confirmation/confirmation_photo_card.dart';

class AttendanceConfirmationView extends ConsumerStatefulWidget {
  final File photoFile;
  final AttendanceEventType action;
  final int? shiftId;
  final WorkLocation? workLocation;
  final VoidCallback onRetake;
  final VoidCallback onSubmittedSuccess;
  final ValueChanged<AttendanceSubmissionResult>? onSubmittedResult;
  final Position? initialPosition;
  final Future<void>? imageProcessFuture;
  final bool isFrontCamera;

  const AttendanceConfirmationView({
    super.key,
    required this.photoFile,
    required this.action,
    this.shiftId,
    this.workLocation,
    required this.onRetake,
    required this.onSubmittedSuccess,
    this.onSubmittedResult,
    this.initialPosition,
    this.imageProcessFuture,
    this.isFrontCamera = true,
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
  String? _pendingIdempotencyKey;

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      try {
        final pos = LocationHelper.validatePosition(
          widget.initialPosition!,
          requireFresh: true,
        );
        _applyValidatedPosition(pos);
      } catch (_) {
        _fetchLocation(forceRefresh: true);
      }
    } else {
      _fetchLocation();
    }
  }

  void _applyValidatedPosition(Position pos) {
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

    _currentPosition = pos;
    _isWithinRadius = within;
    _isLoadingLocation = false;
    _locationError = null;
  }

  Future<void> _fetchLocation({bool forceRefresh = false}) async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final pos = await LocationHelper.determinePosition(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;

      setState(() {
        _applyValidatedPosition(pos);
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

    final isOffline = ref.read(isOfflineProvider);
    if (isOffline) {
      AppHaptics.error();
      ConfirmationDialogs.showOfflineWarningDialog(context);
      return;
    }

    AppHaptics.medium();
    setState(() {
      _isSubmitting = true;
    });

    // Re-validate cached/pre-warmed GPS fix before submission (SEC-19)
    bool needsFreshPosition = _currentPosition == null;
    if (!needsFreshPosition) {
      try {
        LocationHelper.validatePosition(_currentPosition!, requireFresh: true);
      } catch (_) {
        needsFreshPosition = true;
      }
    }

    if (needsFreshPosition) {
      await _fetchLocation(forceRefresh: true);
      if (!mounted) return;
      if (_currentPosition == null) {
        setState(() {
          _isSubmitting = false;
        });
        ConfirmationDialogs.showGpsNotFoundDialog(context, _locationError);
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
      ConfirmationDialogs.showOutsideRadiusDialog(
        context: context,
        distanceMeters: dist,
        allowedRadiusMeters: widget.workLocation!.radius,
      );
      return;
    }

    // Await downsampling in isolate if still running
    if (widget.imageProcessFuture != null) {
      try {
        await widget.imageProcessFuture;
      } catch (_) {}
    }

    _pendingIdempotencyKey ??= AttendanceRepository.generateIdempotencyKey(
      widget.action,
    );

    // Submit attendance event
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
          idempotencyKey: _pendingIdempotencyKey,
        );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });

    if (!success) {
      return;
    }

    _pendingIdempotencyKey = null;

    double distance = 0.0;
    if (widget.workLocation != null && _currentPosition != null) {
      distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        widget.workLocation!.latitude,
        widget.workLocation!.longitude,
      );
    }

    final submissionResult = AttendanceSubmissionResult(
      action: widget.action,
      timestamp: DateTime.now(),
      isWithinRadius: _isWithinRadius,
      distance: distance,
      locationName: widget.workLocation?.name ?? 'Kantor Utama',
    );

    widget.onSubmittedResult?.call(submissionResult);
    widget.onSubmittedSuccess();
  }

  void _openMap() {
    if (_isSubmitting) return;
    if (_currentPosition == null) {
      final err = _locationError?.toLowerCase() ?? '';
      final SnackBarAction? action;
      if (err.contains('permanen')) {
        action = SnackBarAction(
          label: 'Pengaturan',
          textColor: Colors.white,
          onPressed: () => LocationHelper.openAppSettings(),
        );
      } else if (err.contains('nonaktif') || err.contains('gps')) {
        action = SnackBarAction(
          label: 'Aktifkan GPS',
          textColor: Colors.white,
          onPressed: () => LocationHelper.openLocationSettings(),
        );
      } else {
        action = null;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _locationError ??
                'Lokasi GPS belum tersedia. Menghubungkan ulang...',
          ),
          backgroundColor: AppColors.primary,
          action: action,
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

    return PopScope(
      canPop: !_isSubmitting,
      child: Stack(
        children: [
          AbsorbPointer(
            absorbing: _isSubmitting,
            child: Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                child: Column(
                  children: [
                    ConfirmationAppBar(
                      action: widget.action,
                      onRetake: widget.onRetake,
                      onCancel: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ConfirmationPhotoCard(
                          photoFile: widget.photoFile,
                          currentPosition: _currentPosition,
                          isLoadingLocation: _isLoadingLocation,
                          isWithinRadius: _isWithinRadius,
                          locationError: _locationError,
                          workLocation: widget.workLocation,
                          user: user,
                          onOpenMap: _openMap,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: OfflineCardWarning(
                        message:
                            'Koneksi internet terputus. Pastikan data seluler atau Wi-Fi aktif agar presensi dapat dikirim.',
                      ),
                    ),
                    ConfirmationActionButtons(
                      isSubmitting: _isSubmitting,
                      onRetake: widget.onRetake,
                      onSubmit: _submitAttendance,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isSubmitting)
            Positioned.fill(
              child: AbsorbPointer(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.55),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.primary,
                          ),
                          SizedBox(height: 14),
                          Text(
                            'Mengirim presensi...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
