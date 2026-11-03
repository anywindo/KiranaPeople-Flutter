import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_haptics.dart';

class MapTopLocationPill extends StatelessWidget {
  final String officeName;
  final double topPadding;
  final VoidCallback onRefresh;
  final bool isRefreshing;

  const MapTopLocationPill({
    super.key,
    required this.officeName,
    required this.topPadding,
    required this.onRefresh,
    this.isRefreshing = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Positioned(
      top: topPadding + 10,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isDark ? context.borderColor : Colors.transparent,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: isDark ? 0.20 : 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.apartment_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                officeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  AppHaptics.light();
                  onRefresh();
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primary.withValues(alpha: 0.18)
                        : const Color(0xFFFFF1F5),
                    shape: BoxShape.circle,
                  ),
                  child: isRefreshing
                      ? const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.refresh_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

