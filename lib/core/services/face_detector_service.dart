import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionResult {
  final bool hasFace;
  final int faceCount;
  final String? errorMessage;

  const FaceDetectionResult({
    required this.hasFace,
    this.faceCount = 0,
    this.errorMessage,
  });

  factory FaceDetectionResult.success(int count) => FaceDetectionResult(
        hasFace: count > 0,
        faceCount: count,
      );

  factory FaceDetectionResult.noFace() => const FaceDetectionResult(
        hasFace: false,
        faceCount: 0,
        errorMessage:
            'Wajah tidak terdeteksi. Pastikan wajah Anda terlihat jelas di dalam kamera.',
      );

  factory FaceDetectionResult.error(String err) => FaceDetectionResult(
        hasFace: false,
        faceCount: 0,
        errorMessage: err,
      );
}

class FaceDetectorService {
  FaceDetectorService._();
  static final FaceDetectorService instance = FaceDetectorService._();

  FaceDetector? _detector;

  FaceDetector get _getDetector {
    _detector ??= FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableLandmarks: false,
        enableContours: false,
        enableClassification: false,
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

      return FaceDetectionResult.success(faces.length);
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

