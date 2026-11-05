import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_haptics.dart';

class MapControlsOverlay extends StatelessWidget {
  final VoidCallback onRecenter;
  final VoidCallback onFitBounds;

  const MapControlsOverlay({
    super.key,
    required this.onRecenter,
    required this.onFitBounds,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.35 : 0.08,
            ),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.18 : 0.04,
            ),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Lokasi Saya',
            icon: const Icon(
              Icons.near_me_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            onPressed: () {
              AppHaptics.light();
              onRecenter();
            },
          ),
          Container(
            width: 24,
            height: 1.5,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
          IconButton(
            tooltip: 'Tampilkan Semua Titik',
            icon: Icon(
              Icons.zoom_out_map_rounded,
              color: context.textPrimaryColor,
              size: 18,
            ),
            onPressed: () {
              AppHaptics.light();
              onFitBounds();
            },
          ),
        ],
      ),
    );
  }
}
