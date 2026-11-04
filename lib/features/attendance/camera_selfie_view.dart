import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/security/device_security_service.dart';
import '../../core/utils/location_helper.dart';
import '../../data/models/attendance_event_model.dart';
import '../../data/models/work_location_model.dart';
import 'widgets/camera_confirmation_bridge.dart';
import 'widgets/camera_controls_bar.dart';
import 'widgets/camera_device_integrity_dialog.dart';
import 'widgets/camera_preview_surface.dart';
import 'widgets/camera_session_controller.dart';
import 'widgets/camera_top_bar.dart';

export 'widgets/camera_confirmation_bridge.dart';
export 'widgets/camera_controls_bar.dart';
export 'widgets/camera_device_integrity_dialog.dart';
export 'widgets/camera_preview_surface.dart';
export 'widgets/camera_session_controller.dart';
export 'widgets/camera_top_bar.dart';

class CameraSelfieView extends StatefulWidget {
  final AttendanceEventType action;
  final int? shiftId;
  final WorkLocation? workLocation;

  const CameraSelfieView({
    super.key,
    required this.action,
    this.shiftId,
    this.workLocation,
  });

  static Future<bool?> push(
    BuildContext context, {
    required AttendanceEventType action,
    int? shiftId,
    WorkLocation? workLocation,
  }) async {
    // Root / Jailbreak device integrity protection (MASVS-RESILIENCE)
    final isCompromised = await DeviceSecurityService().isDeviceCompromised();
    if (isCompromised && context.mounted) {
      await CameraDeviceIntegrityDialog.show(context);
      return false;
    }

    if (!context.mounted) return false;
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CameraSelfieView(
          action: action,
          shiftId: shiftId,
          workLocation: workLocation,
        ),
      ),
    );
  }

  @override
  State<CameraSelfieView> createState() => _CameraSelfieViewState();
}

class _CameraSelfieViewState extends State<CameraSelfieView>
    with WidgetsBindingObserver {
  late final CameraSessionController _cameraSession;
  File? _capturedPhoto;
  Position? _warmedPosition;
  Future<void>? _imageProcessFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraSession = CameraSessionController();
    _cameraSession.addListener(_onSessionUpdated);

    // Pre-warm GPS & Device Integrity in parallel while framing selfie
    LocationHelper.warmupPosition().then((pos) {
      if (mounted) {
        _warmedPosition = pos;
      }
    });
    DeviceSecurityService().getReport();
    _cameraSession.initialize();
  }

  void _onSessionUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  void _cleanupCapturedPhoto() {
    if (_capturedPhoto != null) {
      try {
        if (_capturedPhoto!.existsSync()) {
          _capturedPhoto!.deleteSync();
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraSession.removeListener(_onSessionUpdated);
    _cameraSession.dispose();
    _cleanupCapturedPhoto();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _cameraSession.handleLifecycleState(state);
  }

  Future<void> _takePicture() async {
    final photo = await _cameraSession.takePicture(
      onProcessStarted: (future) {
        _imageProcessFuture = future;
      },
    );

    if (photo != null && mounted) {
      // Clean up previous photo file if different
      if (_capturedPhoto != null && _capturedPhoto!.path != photo.path) {
        _cleanupCapturedPhoto();
      }
      setState(() {
        _capturedPhoto = photo;
      });
    }
  }

  Future<void> _retakePhoto() async {
    _imageProcessFuture = null;
    _cleanupCapturedPhoto();
    await _cameraSession.resumePreview();
    if (mounted) {
      setState(() {
        _capturedPhoto = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If photo captured, transition to Confirmation Screen
    if (_capturedPhoto != null) {
      return CameraConfirmationBridge(
        photoFile: _capturedPhoto!,
        action: widget.action,
        shiftId: widget.shiftId,
        workLocation: widget.workLocation,
        initialPosition: _warmedPosition,
        imageProcessFuture: _imageProcessFuture,
        isFrontCamera: _cameraSession.isCurrentCameraFront,
        onRetake: _retakePhoto,
        onSubmittedSuccess: () {
          Navigator.pop(context, true);
        },
      );
    }

    // Live Camera Screen
    final bool isFront = _cameraSession.isCurrentCameraFront;
    final bool isScreenFlashWarmup = _cameraSession.isFlashOn && isFront;
    final Color textColor = isScreenFlashWarmup ? Colors.black87 : Colors.white;

    return Scaffold(
      backgroundColor:
          isScreenFlashWarmup ? const Color(0xFFFBFBFB) : Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                CameraTopBar(
                  action: widget.action,
                  textColor: textColor,
                  onBack: () => Navigator.pop(context),
                ),

                // Camera Viewport + Headroom Overlay
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CameraPreviewSurface(
                      controller: _cameraSession.controller,
                      isCameraReady: _cameraSession.isCameraReady,
                      isScreenFlashWarmup: isScreenFlashWarmup,
                    ),
                  ),
                ),

                // Bottom Controls Bar (Flash, Shutter, Switch Camera)
                CameraControlsBar(
                  isFlashOn: _cameraSession.isFlashOn,
                  isScreenFlashWarmup: isScreenFlashWarmup,
                  isTakingPhoto: _cameraSession.isTakingPhoto,
                  onToggleFlash: _cameraSession.toggleFlash,
                  onTakePicture: _takePicture,
                  onToggleCamera: _cameraSession.toggleCamera,
                ),
              ],
            ),
          ),

          // Full-screen blinding white burst during screen flash capture
          if (_cameraSession.isScreenFlashing)
            Positioned.fill(
              child: Container(
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
