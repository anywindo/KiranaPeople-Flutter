import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageProcessParams {
  final String path;
  final int sensorOrientation;
  final bool isFrontCamera;

  const ImageProcessParams({
    required this.path,
    required this.sensorOrientation,
    required this.isFrontCamera,
  });
}

class FastImageProcessor {
  FastImageProcessor._();

  /// Background isolate image processor to keep UI thread 100% responsive and avoid ANR/OOM.
  /// Downsamples to max 1000px, bakes orientation/rotation, and compresses at 75 quality.
  static Future<void> processImageFast({
    required String path,
    required int sensorOrientation,
    required bool isFrontCamera,
  }) async {
    final file = File(path);
    if (!await file.exists()) return;

    await compute(
      processImageInIsolate,
      ImageProcessParams(
        path: path,
        sensorOrientation: sensorOrientation,
        isFrontCamera: isFrontCamera,
      ),
    );
  }

  /// Background isolate image processor to keep UI thread 100% responsive
  static Future<void> processImageInIsolate(ImageProcessParams params) async {
    final file = File(params.path);
    if (!await file.exists()) return;

    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return;

    // 1. Immediately downsample BEFORE performing rotation / orientation / flip.
    img.Image working = decoded;
    const int maxDim = 1000;
    if (working.height > maxDim || working.width > maxDim) {
      working = img.copyResize(
        working,
        height: working.height > working.width ? maxDim : null,
        width: working.width >= working.height ? maxDim : null,
        interpolation: img.Interpolation.linear,
      );
    }

    working = img.bakeOrientation(working);
    if (working.width > working.height) {
      final rotationAngle = params.sensorOrientation == 90 ? 90 : 270;
      working = img.copyRotate(working, angle: rotationAngle);
    }

    if (params.isFrontCamera) {
      working = img.flipHorizontal(working);
    }

    // Compress at quality 75 and write atomically via temp file
    final encoded = img.encodeJpg(working, quality: 75);
    final tmpFile = File('${params.path}.tmp');
    await tmpFile.writeAsBytes(encoded, flush: true);
    await tmpFile.rename(params.path);
  }
}
