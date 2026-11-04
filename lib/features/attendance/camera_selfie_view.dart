import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/security/device_security_service.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/utils/location_helper.dart';
import '../../data/models/attendance_event_model.dart';
import '../../data/models/work_location_model.dart';
import 'attendance_confirmation_view.dart';
import 'widgets/camera_controls_bar.dart';
import 'widgets/camera_device_integrity_dialog.dart';
import 'widgets/camera_preview_surface.dart';
import 'widgets/camera_top_bar.dart';
import 'widgets/fast_image_processor.dart';

export 'widgets/camera_controls_bar.dart';
export 'widgets/camera_device_integrity_dialog.dart';
export 'widgets/camera_preview_surface.dart';
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
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraReady = false;
  bool _isTakingPhoto = false;
  bool _isFlashOn = false;
  bool _isScreenFlashing = false;
  File? _capturedPhoto;
  Position? _warmedPosition;
  Future<void>? _imageProcessFuture;

  bool get _isCurrentCameraFront {
    if (_cameras.isEmpty || _selectedCameraIndex >= _cameras.length) {
      return true;
    }
    return _cameras[_selectedCameraIndex].lensDirection ==
        CameraLensDirection.front;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Pre-warm GPS & Device Integrity in parallel while framing selfie
    LocationHelper.warmupPosition().then((pos) {
      if (mounted) {
        _warmedPosition = pos;
      }
    });
    DeviceSecurityService().getReport();
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    if (_capturedPhoto != null) {
      try {
        if (_capturedPhoto!.existsSync()) {
          _capturedPhoto!.deleteSync();
        }
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      cameraController.dispose();
      _controller = null;
      if (mounted) {
        setState(() {
          _isCameraReady = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_cameras.isNotEmpty) {
        _setupCameraController(_cameras[_selectedCameraIndex]);
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _isCameraReady = false;
        });
        return;
      }

      // Default to front camera for selfie
      final frontIndex = _cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.front);
      _selectedCameraIndex = frontIndex != -1 ? frontIndex : 0;
      await _setupCameraController(_cameras[_selectedCameraIndex]);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isCameraReady = false;
        });
      }
    }
  }

  Future<void> _setupCameraController(CameraDescription description) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();

      // Configure hardware flash safely only if enabled and on rear camera
      if (_isFlashOn && description.lensDirection != CameraLensDirection.front) {
        try {
          await _controller!.setFlashMode(FlashMode.always);
        } catch (_) {
          try {
            await _controller!.setFlashMode(FlashMode.torch);
          } catch (_) {}
        }
      } else {
        try {
          await _controller!.setFlashMode(FlashMode.off);
        } catch (_) {}
      }

      try {
        await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isCameraReady = false;
        });
      }
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras.length <= 1) return;
    AppHaptics.selection();
    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    setState(() {
      _isCameraReady = false;
      _selectedCameraIndex = nextIndex;
    });
    await _setupCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_isCameraReady) return;
    AppHaptics.light();

    final nextFlashState = !_isFlashOn;

    // For rear camera, attempt to configure physical hardware flash
    if (!_isCurrentCameraFront) {
      try {
        await _controller!.setFlashMode(
          nextFlashState ? FlashMode.always : FlashMode.off,
        );
      } catch (_) {
        try {
          await _controller!.setFlashMode(
            nextFlashState ? FlashMode.torch : FlashMode.off,
          );
        } catch (_) {}
      }
    } else {
      // Front camera uses Screen Flash
      try {
        await _controller!.setFlashMode(FlashMode.off);
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _isFlashOn = nextFlashState;
      });
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_isCameraReady || _isTakingPhoto) return;
    AppHaptics.medium();

    try {
      setState(() {
        _isTakingPhoto = true;
      });

      final bool isFront = _isCurrentCameraFront;
      final bool needsScreenFlash = _isFlashOn && isFront;

      if (needsScreenFlash) {
        setState(() {
          _isScreenFlashing = true;
        });
        await Future.delayed(const Duration(milliseconds: 250));
      }

      final image = await _controller!.takePicture();
      final file = File(image.path);

      try {
        final sensorOrientation = _cameras.isNotEmpty
            ? _cameras[_selectedCameraIndex].sensorOrientation
            : 270;

        final future = FastImageProcessor.processImageFast(
          path: file.path,
          sensorOrientation: sensorOrientation,
          isFrontCamera: isFront,
        );
        _imageProcessFuture = future;
        await future;
        await FileImage(file).evict();
      } catch (_) {}

      if (mounted) {
        try {
          await _controller?.pausePreview();
        } catch (_) {}
        // Clean up previously captured file before storing the new one
        if (_capturedPhoto != null && _capturedPhoto!.path != file.path) {
          try {
            if (_capturedPhoto!.existsSync()) {
              _capturedPhoto!.deleteSync();
            }
          } catch (_) {}
        }
        setState(() {
          _capturedPhoto = file;
          _isTakingPhoto = false;
          _isScreenFlashing = false;
        });
        AppHaptics.light();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isTakingPhoto = false;
          _isScreenFlashing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If photo captured, transition to Confirmation Screen
    if (_capturedPhoto != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          _imageProcessFuture = null;
          if (_capturedPhoto != null) {
            try {
              if (await _capturedPhoto!.exists()) {
                await _capturedPhoto!.delete();
              }
            } catch (_) {}
          }
          try {
            await _controller?.resumePreview();
          } catch (_) {}
          if (mounted) {
            setState(() {
              _capturedPhoto = null;
            });
          }
        },
        child: AttendanceConfirmationView(
          photoFile: _capturedPhoto!,
          action: widget.action,
          shiftId: widget.shiftId,
          workLocation: widget.workLocation,
          initialPosition: _warmedPosition,
          imageProcessFuture: _imageProcessFuture,
          isFrontCamera: _isCurrentCameraFront,
          onRetake: () async {
            _imageProcessFuture = null;
            if (_capturedPhoto != null) {
              try {
                if (await _capturedPhoto!.exists()) {
                  await _capturedPhoto!.delete();
                }
              } catch (_) {}
            }
            try {
              await _controller?.resumePreview();
            } catch (_) {}
            if (mounted) {
              setState(() {
                _capturedPhoto = null;
              });
            }
          },
          onSubmittedSuccess: () {
            Navigator.pop(context, true);
          },
        ),
      );
    }

    // Live Camera Screen
    final bool isFront = _isCurrentCameraFront;
    final bool isScreenFlashWarmup = _isFlashOn && isFront;
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
                      controller: _controller,
                      isCameraReady: _isCameraReady,
                      isScreenFlashWarmup: isScreenFlashWarmup,
                    ),
                  ),
                ),

                // Bottom Controls Bar (Flash, Shutter, Switch Camera)
                CameraControlsBar(
                  isFlashOn: _isFlashOn,
                  isScreenFlashWarmup: isScreenFlashWarmup,
                  isTakingPhoto: _isTakingPhoto,
                  onToggleFlash: _toggleFlash,
                  onTakePicture: _takePicture,
                  onToggleCamera: _toggleCamera,
                ),
              ],
            ),
          ),

          // Full-screen blinding white burst during screen flash capture
          if (_isScreenFlashing)
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
