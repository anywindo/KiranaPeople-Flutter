import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_haptics.dart';

class CameraControlsBar extends StatelessWidget {
  final bool isFlashOn;
  final bool isScreenFlashWarmup;
  final bool isTakingPhoto;
  final VoidCallback onToggleFlash;
  final VoidCallback onTakePicture;
  final VoidCallback onToggleCamera;

  const CameraControlsBar({
    super.key,
    required this.isFlashOn,
    required this.isScreenFlashWarmup,
    required this.isTakingPhoto,
    required this.onToggleFlash,
    required this.onTakePicture,
    required this.onToggleCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Flash toggle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isFlashOn
                  ? AppColors.warning.withValues(alpha: 0.2)
                  : (isScreenFlashWarmup
                        ? const Color(0xFFE4E4E7)
                        : const Color(0xFF27272A)),
              shape: BoxShape.circle,
              border: isFlashOn
                  ? Border.all(color: AppColors.warning, width: 2)
                  : null,
            ),
            child: IconButton(
              tooltip: isFlashOn ? 'Flash On' : 'Flash Off',
              icon: Icon(
                isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: isFlashOn
                    ? AppColors.warning
                    : (isScreenFlashWarmup ? Colors.black54 : Colors.white70),
                size: 22,
              ),
              onPressed: () {
                AppHaptics.light();
                onToggleFlash();
              },
            ),
          ),

          // Center Shutter Button (concentric circles + tactile shadow)
          GestureDetector(
            onTap: isTakingPhoto
                ? null
                : () {
                    AppHaptics.medium();
                    onTakePicture();
                  },
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isScreenFlashWarmup ? Colors.black87 : Colors.white,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(5),
              child: Container(
                decoration: BoxDecoration(
                  color: isScreenFlashWarmup ? Colors.black87 : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isTakingPhoto
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: isScreenFlashWarmup
                                ? Colors.white
                                : Colors.black,
                          ),
                        )
                      : Icon(
                          Icons.camera_alt_rounded,
                          color: isScreenFlashWarmup
                              ? Colors.white
                              : Colors.black,
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
            decoration: BoxDecoration(
              color: isScreenFlashWarmup
                  ? const Color(0xFFE4E4E7)
                  : const Color(0xFF27272A),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.cameraswitch_rounded,
                color: isScreenFlashWarmup ? Colors.black54 : Colors.white70,
                size: 22,
              ),
              onPressed: () {
                AppHaptics.light();
                onToggleCamera();
              },
            ),
          ),
        ],
      ),
    );
  }
}
