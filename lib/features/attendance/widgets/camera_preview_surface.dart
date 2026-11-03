import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class CameraPreviewSurface extends StatelessWidget {
  final CameraController? controller;
  final bool isCameraReady;
  final bool isScreenFlashWarmup;

  const CameraPreviewSurface({
    super.key,
    required this.controller,
    required this.isCameraReady,
    required this.isScreenFlashWarmup,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          // Camera Preview or Fallback
          if (isCameraReady && controller != null && controller!.value.isInitialized)
            LayoutBuilder(
              builder: (context, constraints) {
                final double containerWidth = constraints.maxWidth;
                final double containerHeight = constraints.maxHeight;
                final double containerRatio = containerWidth / containerHeight;

                // Calculate camera sensor aspect ratio in portrait
                final bool isPortrait =
                    MediaQuery.of(context).orientation == Orientation.portrait;
                final double rawAspect = controller!.value.aspectRatio;
                final double previewRatio = isPortrait
                    ? (rawAspect > 1 ? 1.0 / rawAspect : rawAspect)
                    : (rawAspect < 1 ? 1.0 / rawAspect : rawAspect);

                double targetWidth;
                double targetHeight;

                if (containerRatio > previewRatio) {
                  targetWidth = containerWidth;
                  targetHeight = containerWidth / previewRatio;
                } else {
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
                        child: CameraPreview(controller!),
                      ),
                    ),
                  ),
                );
              },
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
                color: isScreenFlashWarmup ? Colors.black45 : null,
                errorBuilder: (context, error, stackTrace) {
                  return CustomPaint(
                    painter: SilhouettePainter(
                      strokeColor: isScreenFlashWarmup
                          ? Colors.black54
                          : Colors.white.withValues(alpha: 0.70),
                    ),
                    size: const Size(260, 360),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SilhouettePainter extends CustomPainter {
  final Color strokeColor;

  const SilhouettePainter({
    this.strokeColor = const Color(0xB3FFFFFF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
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
  bool shouldRepaint(covariant SilhouettePainter oldDelegate) =>
      oldDelegate.strokeColor != strokeColor;
}

