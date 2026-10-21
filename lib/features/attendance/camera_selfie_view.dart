import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '../../core/theme/app_theme.dart';
import '../../data/models/attendance_event_model.dart';
import '../../data/models/work_location_model.dart';
import 'attendance_confirmation_view.dart';

class _ImageProcessParams {
  final String path;
  final int sensorOrientation;
  final bool isFrontCamera;

  const _ImageProcessParams({
    required this.path,
    required this.sensorOrientation,
    required this.isFrontCamera,
  });
}

// Background isolate image processor to keep UI thread 100% responsive and avoid ANR/OOM
Future<void> _processImageInIsolate(_ImageProcessParams params) async {
  final file = File(params.path);
  if (!await file.exists()) return;

  final bytes = await file.readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return;

  img.Image oriented = img.bakeOrientation(decoded);
  if (oriented.width > oriented.height) {
    final rotationAngle = params.sensorOrientation == 90 ? 90 : 270;
    oriented = img.copyRotate(oriented, angle: rotationAngle);
  }

  if (params.isFrontCamera) {
    oriented = img.flipHorizontal(oriented);
  }

  // Downsample to max 1280px on longest side for optimal speed, quality, and upload efficiency
  if (oriented.height > 1280 || oriented.width > 1280) {
    oriented = img.copyResize(
      oriented,
      height: oriented.height > oriented.width ? 1280 : null,
      width: oriented.width >= oriented.height ? 1280 : null,
    );
  }

  final encoded = img.encodeJpg(oriented, quality: 85);
  await file.writeAsBytes(encoded);
}

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
  }) {
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
  FlashMode _flashMode = FlashMode.off;
  File? _capturedPhoto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
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
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      await _controller!.setFlashMode(_flashMode);
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
    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    setState(() {
      _isCameraReady = false;
      _selectedCameraIndex = nextIndex;
    });
    await _setupCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_isCameraReady) return;
    final nextMode =
        _flashMode == FlashMode.off ? FlashMode.always : FlashMode.off;
    try {
      await _controller!.setFlashMode(nextMode);
      setState(() {
        _flashMode = nextMode;
      });
    } catch (_) {}
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_isCameraReady || _isTakingPhoto) return;

    try {
      setState(() {
        _isTakingPhoto = true;
      });

      final image = await _controller!.takePicture();
      final file = File(image.path);

      try {
        final sensorOrientation = _cameras.isNotEmpty
            ? _cameras[_selectedCameraIndex].sensorOrientation
            : 270;
        final bool isFrontCamera = _cameras.isNotEmpty
            ? _cameras[_selectedCameraIndex].lensDirection ==
                CameraLensDirection.front
            : true;

        await compute(
          _processImageInIsolate,
          _ImageProcessParams(
            path: file.path,
            sensorOrientation: sensorOrientation,
            isFrontCamera: isFrontCamera,
          ),
        );
      } catch (_) {}

      if (mounted) {
        try {
          await _controller?.pausePreview();
        } catch (_) {}
        setState(() {
          _capturedPhoto = file;
          _isTakingPhoto = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isTakingPhoto = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If photo captured, transition to Confirmation Screen (Screenshot 4)
    if (_capturedPhoto != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
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
          onRetake: () async {
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

    // Live Camera Screen (Screenshot 3)
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded,
                        color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.action.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer to balance back button
                ],
              ),
            ),

            // Camera Viewport + Headroom Overlay
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  // Camera Preview or Fallback
                  if (_isCameraReady &&
                      _controller != null &&
                      _controller!.value.isInitialized)
                    Center(
                      child: AspectRatio(
                        aspectRatio: 3 / 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final double containerWidth =
                                  constraints.maxWidth;
                              final double containerHeight =
                                  constraints.maxHeight;
                              final double containerRatio =
                                  containerWidth / containerHeight;

                              // Calculate camera sensor aspect ratio in portrait
                              final bool isPortrait = MediaQuery.of(context)
                                      .orientation ==
                                  Orientation.portrait;
                              final double rawAspect =
                                  _controller!.value.aspectRatio;
                              final double previewRatio = isPortrait
                                  ? (rawAspect > 1
                                      ? 1.0 / rawAspect
                                      : rawAspect)
                                  : (rawAspect < 1
                                      ? 1.0 / rawAspect
                                      : rawAspect);

                              double targetWidth;
                              double targetHeight;

                              if (containerRatio > previewRatio) {
                                // Container is wider than preview -> match width, crop top/bottom
                                targetWidth = containerWidth;
                                targetHeight = containerWidth / previewRatio;
                              } else {
                                // Container is taller than preview -> match height, crop left/right
                                targetHeight = containerHeight;
                                targetWidth = containerHeight * previewRatio;
                              }

                              return SizedBox(
                                width: containerWidth,
                                height: containerHeight,
                                child: ClipRect(
                                  child: OverflowBox(
                                    alignment: Alignment.center,
                                    maxWidth: targetWidth,
                                    maxHeight: targetHeight,
                                    minWidth: targetWidth,
                                    minHeight: targetHeight,
                                    child: SizedBox(
                                      width: targetWidth,
                                      height: targetHeight,
                                      child: CameraPreview(_controller!),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),

                  // Headroom Face Guide Overlay
                  Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.85,
                      child: Image.asset(
                        'assets/images/Headroom.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback custom paint silhouette if asset fails
                          return CustomPaint(
                            painter: _SilhouettePainter(),
                            size: const Size(260, 360),
                          );
                        },
                      ),
                    ),
                  ),

                  // Flash effect during capture
                  if (_isTakingPhoto)
                    Container(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                ],
              ),
            ),

            // Bottom Controls Bar (Flash, Shutter, Switch Camera)
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Flash toggle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF27272A),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _flashMode == FlashMode.off
                            ? Icons.flash_off_rounded
                            : Icons.flash_on_rounded,
                        color: _flashMode == FlashMode.off
                            ? Colors.white70
                            : AppColors.warning,
                        size: 22,
                      ),
                      onPressed: _toggleFlash,
                    ),
                  ),

                  // Center Shutter Button (concentric circles + camera icon)
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.black,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Flip camera
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFF27272A),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.cameraswitch_rounded,
                        color: Colors.white70,
                        size: 22,
                      ),
                      onPressed: _toggleCamera,
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
}

class _SilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final path = Path();
    // Head circle
    final centerHead = Offset(size.width / 2, size.height * 0.35);
    final headRadius = size.width * 0.28;
    path.addOval(Rect.fromCircle(center: centerHead, radius: headRadius));

    // Shoulders arch
    path.moveTo(size.width * 0.15, size.height * 0.95);
    path.quadraticBezierTo(
      size.width * 0.20,
      size.height * 0.65,
      size.width * 0.35,
      size.height * 0.60,
    );
    path.moveTo(size.width * 0.85, size.height * 0.95);
    path.quadraticBezierTo(
      size.width * 0.80,
      size.height * 0.65,
      size.width * 0.65,
      size.height * 0.60,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
