import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/utils/app_haptics.dart';
import '../../attendance/widgets/camera_controls_bar.dart';
import '../../attendance/widgets/camera_preview_surface.dart';
import '../../attendance/widgets/camera_session_controller.dart';

class ProfileCameraView extends StatefulWidget {
  const ProfileCameraView({super.key});

  static Future<File?> push(BuildContext context) async {
    return Navigator.push<File?>(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileCameraView(),
      ),
    );
  }

  @override
  State<ProfileCameraView> createState() => _ProfileCameraViewState();
}

class _ProfileCameraViewState extends State<ProfileCameraView>
    with WidgetsBindingObserver {
  late final CameraSessionController _cameraSession;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraSession = CameraSessionController();
    _cameraSession.addListener(_onSessionUpdated);
    _cameraSession.initialize();
  }

  void _onSessionUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _cameraSession.handleLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraSession.removeListener(_onSessionUpdated);
    _cameraSession.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final file = await _cameraSession.takePicture();
    if (file != null && mounted) {
      Navigator.pop(context, file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isScreenFlash = _cameraSession.isScreenFlashing;

    return Scaffold(
      backgroundColor: isScreenFlash ? Colors.white : Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isScreenFlash ? Colors.black : Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      AppHaptics.light();
                      Navigator.pop(context);
                    },
                  ),
                  Text(
                    'Ambil Foto Profil',
                    style: TextStyle(
                      color: isScreenFlash ? Colors.black : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Camera Preview Surface
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CameraPreviewSurface(
                  controller: _cameraSession.controller,
                  isCameraReady: _cameraSession.isCameraReady,
                  isScreenFlashWarmup: isScreenFlash,
                ),
              ),
            ),

            // Guidance text
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Posisikan wajah Anda di dalam frame',
                style: TextStyle(
                  color: isScreenFlash
                      ? Colors.black54
                      : Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Bottom Controls Bar
            CameraControlsBar(
              isFlashOn: _cameraSession.isFlashOn,
              isScreenFlashWarmup: isScreenFlash,
              isTakingPhoto: _cameraSession.isTakingPhoto,
              onToggleFlash: _cameraSession.toggleFlash,
              onTakePicture: _takePhoto,
              onToggleCamera: _cameraSession.toggleCamera,
            ),
          ],
        ),
      ),
    );
  }
}

