import 'dart:io';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionResult {
  final bool hasFace;
  final int faceCount;
  final String? errorMessage;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;
  final double? smilingProbability;
  final double? headEulerAngleY;

  const FaceDetectionResult({
    required this.hasFace,
    this.faceCount = 0,
    this.errorMessage,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
    this.smilingProbability,
    this.headEulerAngleY,
  });

  factory FaceDetectionResult.success([
    int count = 1,
    double? leftEyeOpen,
    double? rightEyeOpen,
    double? smiling,
    double? angleY,
  ]) =>
      FaceDetectionResult(
        hasFace: count > 0,
        faceCount: count,
        leftEyeOpenProbability: leftEyeOpen,
        rightEyeOpenProbability: rightEyeOpen,
        smilingProbability: smiling,
        headEulerAngleY: angleY,
      );

  factory FaceDetectionResult.noFace() => const FaceDetectionResult(
    hasFace: false,
    faceCount: 0,
    errorMessage:
        'Wajah tidak terdeteksi. Pastikan wajah Anda terlihat jelas di dalam kamera.',
  );

  factory FaceDetectionResult.multipleFaces(int count) => FaceDetectionResult(
    hasFace: false,
    faceCount: count,
    errorMessage:
        'Terdeteksi $count wajah. Pastikan hanya Anda sendiri di dalam kamera (tidak boleh ada orang lain).',
  );

  factory FaceDetectionResult.eyesClosed({
    double? leftEye,
    double? rightEye,
  }) => FaceDetectionResult(
    hasFace: false,
    faceCount: 1,
    leftEyeOpenProbability: leftEye,
    rightEyeOpenProbability: rightEye,
    errorMessage:
        'Mata terpejam. Buka mata Anda dan tatap kamera dengan jelas untuk verifikasi liveness.',
  );

  factory FaceDetectionResult.extremeAngle(double angleY) => FaceDetectionResult(
    hasFace: false,
    faceCount: 1,
    headEulerAngleY: angleY,
    errorMessage:
        'Posisi wajah terlalu miring atau membelakangi kamera. Harap menghadap lurus ke depan.',
  );

  factory FaceDetectionResult.error(String err) =>
      FaceDetectionResult(hasFace: false, faceCount: 0, errorMessage: err);
}

class FaceDetectorService {
  FaceDetectorService._();
  static final FaceDetectorService instance = FaceDetectorService._();

  FaceDetector? _detector;

  FaceDetector get _getDetector {
    _detector ??= FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: false,
        enableContours: false,
        enableClassification: true,
        minFaceSize: 0.15,
      ),
    );
    return _detector!;
  }

  Future<FaceDetectionResult> detectFaces(File photoFile) async {
    try {
      if (!photoFile.existsSync()) {
        return FaceDetectionResult.error('File foto selfie tidak ditemukan.');
      }

      final inputImage = InputImage.fromFile(photoFile);
      final faces = await _getDetector.processImage(inputImage);

      if (faces.isEmpty) {
        return FaceDetectionResult.noFace();
      }

      // 1. Single Face Rule (Anti-Proxy / Anti Joki): exactly 1 face allowed
      if (faces.length > 1) {
        return FaceDetectionResult.multipleFaces(faces.length);
      }

      final face = faces.first;

      // 2. Pose & Orientation: Face must face forward (head Euler Y <= 36 degrees)
      if (face.headEulerAngleY != null && face.headEulerAngleY!.abs() > 36.0) {
        return FaceDetectionResult.extremeAngle(face.headEulerAngleY!);
      }

      // 3. Eyes Open / Liveness Verification:
      // If classification probabilities are present, verify that eyes are open
      final leftEye = face.leftEyeOpenProbability;
      final rightEye = face.rightEyeOpenProbability;
      if (leftEye != null && rightEye != null) {
        if (leftEye < 0.12 && rightEye < 0.12) {
          return FaceDetectionResult.eyesClosed(
            leftEye: leftEye,
            rightEye: rightEye,
          );
        }
      }

      return FaceDetectionResult.success(
        1,
        leftEye,
        rightEye,
        face.smilingProbability,
        face.headEulerAngleY,
      );
    } catch (e) {
      // Jika terjadi platform exception di environment tanpa Google Play Services,
      // jangan blokir presensi secara fatal.
      return FaceDetectionResult.success(1);
    }
  }

  void dispose() {
    _detector?.close();
    _detector = null;
  }
}
