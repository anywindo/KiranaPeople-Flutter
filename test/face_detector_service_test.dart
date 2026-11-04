import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/core/services/face_detector_service.dart';

void main() {
  group('FaceDetectorService Tests', () {
    test('FaceDetectionResult model holds state properly', () {
      final successResult = FaceDetectionResult.success(2);
      expect(successResult.hasFace, isTrue);
      expect(successResult.faceCount, equals(2));
      expect(successResult.errorMessage, isNull);

      final noFaceResult = FaceDetectionResult.noFace();
      expect(noFaceResult.hasFace, isFalse);
      expect(noFaceResult.faceCount, equals(0));
      expect(noFaceResult.errorMessage, contains('Wajah tidak terdeteksi'));

      final errorResult = FaceDetectionResult.error('Kamera error');
      expect(errorResult.hasFace, isFalse);
      expect(errorResult.errorMessage, equals('Kamera error'));
    });

    test('detectFaces returns error when file does not exist', () async {
      final nonExistentFile = File('/path/to/non_existent_selfie_image.jpg');
      final result = await FaceDetectorService.instance.detectFaces(nonExistentFile);

      expect(result.hasFace, isFalse);
      expect(result.errorMessage, contains('tidak ditemukan'));
    });
  });
}

