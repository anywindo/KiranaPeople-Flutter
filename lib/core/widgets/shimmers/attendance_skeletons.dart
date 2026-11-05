import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../shimmer_loading.dart';

/// Skeleton for the Shift Info Card on the Attendance Screen
class ShiftInfoCardSkeleton extends StatelessWidget {
  const ShiftInfoCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ShimmerLoading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shift Title & Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                SkeletonText(width: 130, height: 20),
                SkeletonBox(
                  width: 80,
                  height: 26,
                  borderRadius: BorderRadius.all(Radius.circular(13)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Schedule times bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  SkeletonText(width: 100, height: 16),
                  SkeletonText(width: 60, height: 16),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Big Action Button Skeleton
            const SkeletonBox(
              width: double.infinity,
              height: 52,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full screen skeleton loader for Attendance Screen initial load
class AttendanceScreenSkeleton extends StatelessWidget {
  const AttendanceScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: ShimmerLoading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header Skeleton
            Row(
              children: [
                const SkeletonBox.circle(size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonText(width: 90, height: 12),
                      SizedBox(height: 6),
                      SkeletonText(width: 150, height: 18),
                    ],
                  ),
                ),
                const SkeletonBox.circle(size: 38),
                const SizedBox(width: 8),
                const SkeletonBox.circle(size: 38),
              ],
            ),
            const SizedBox(height: 16),

            // Mode Switcher Skeleton
            const SkeletonBox(
              width: double.infinity,
              height: 44,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            const SizedBox(height: 16),

            // Shift Card Skeleton
            const ShiftInfoCardSkeleton(),
            const SizedBox(height: 20),

            // Activity timeline title & items
            const SkeletonText(width: 140, height: 18),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: const [
                  TimelineRowSkeleton(),
                  SizedBox(height: 16),
                  TimelineRowSkeleton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimelineRowSkeleton extends StatelessWidget {
  const TimelineRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        SkeletonBox.circle(size: 32),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonText(width: 100, height: 14),
              SizedBox(height: 4),
              SkeletonText(width: 140, height: 11),
            ],
          ),
        ),
        SkeletonText(width: 48, height: 14),
      ],
    );
  }
}
