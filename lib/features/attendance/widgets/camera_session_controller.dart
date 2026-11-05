import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/app_haptics.dart';
import 'fast_image_processor.dart';

class CameraSessionController extends ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraReady = false;
  bool _isTakingPhoto = false;
  bool _isFlashOn = false;
  bool _isScreenFlashing = false;

  CameraController? get controller => _controller;
  List<CameraDescription> get cameras => _cameras;
  int get selectedCameraIndex => _selectedCameraIndex;
  bool get isCameraReady => _isCameraReady;
  bool get isTakingPhoto => _isTakingPhoto;
  bool get isFlashOn => _isFlashOn;
  bool get isScreenFlashing => _isScreenFlashing;

  bool get isCurrentCameraFront {
    if (_cameras.isEmpty || _selectedCameraIndex >= _cameras.length) {
      return true;
    }
    return _cameras[_selectedCameraIndex].lensDirection ==
        CameraLensDirection.front;
  }

  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _isCameraReady = false;
        notifyListeners();
        return;
      }

      // Default to front camera for selfie
      final frontIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      _selectedCameraIndex = frontIndex != -1 ? frontIndex : 0;
      await setupCameraController(_cameras[_selectedCameraIndex]);
    } catch (_) {
      _isCameraReady = false;
      notifyListeners();
    }
  }

  Future<void> setupCameraController(CameraDescription description) async {
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
      if (_isFlashOn &&
          description.lensDirection != CameraLensDirection.front) {
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

      _isCameraReady = true;
      notifyListeners();
    } catch (_) {
      _isCameraReady = false;
      notifyListeners();
    }
  }

  Future<void> handleLifecycleState(AppLifecycleState state) async {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      cameraController.dispose();
      _controller = null;
      _isCameraReady = false;
      notifyListeners();
    } else if (state == AppLifecycleState.resumed) {
      if (_cameras.isNotEmpty) {
        await setupCameraController(_cameras[_selectedCameraIndex]);
      }
    }
  }

  Future<void> toggleCamera() async {
    if (_cameras.length <= 1) return;
    AppHaptics.selection();
    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _isCameraReady = false;
    _selectedCameraIndex = nextIndex;
    notifyListeners();
    await setupCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<void> toggleFlash() async {
    if (_controller == null || !_isCameraReady) return;
    AppHaptics.light();

    final nextFlashState = !_isFlashOn;

    // For rear camera, attempt to configure physical hardware flash
    if (!isCurrentCameraFront) {
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

    _isFlashOn = nextFlashState;
    notifyListeners();
  }

  Future<File?> takePicture({
    Function(Future<void> processFuture)? onProcessStarted,
  }) async {
    if (_controller == null || !_isCameraReady || _isTakingPhoto) return null;
    AppHaptics.medium();

    try {
      _isTakingPhoto = true;
      notifyListeners();

      final bool isFront = isCurrentCameraFront;
      final bool needsScreenFlash = _isFlashOn && isFront;

      if (needsScreenFlash) {
        _isScreenFlashing = true;
        notifyListeners();
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
        onProcessStarted?.call(future);
        await future;
        await FileImage(file).evict();
      } catch (_) {}

      try {
        await _controller?.pausePreview();
      } catch (_) {}

      _isTakingPhoto = false;
      _isScreenFlashing = false;
      notifyListeners();
      AppHaptics.light();
      return file;
    } catch (_) {
      _isTakingPhoto = false;
      _isScreenFlashing = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> pausePreview() async {
    try {
      await _controller?.pausePreview();
    } catch (_) {}
  }

  Future<void> resumePreview() async {
    try {
      await _controller?.resumePreview();
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
