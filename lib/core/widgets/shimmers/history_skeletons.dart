import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../shimmer_loading.dart';

/// Realistic Skeleton Card replicating the Attendance History Card
class HistoryCardSkeleton extends StatelessWidget {
  const HistoryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE5E7EB);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.2),
      ),
      child: ShimmerLoading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Date & Status Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const SkeletonBox.circle(size: 20),
                    const SizedBox(width: 8),
                    SkeletonText(
                      width: MediaQuery.of(context).size.width * 0.35,
                      height: 16,
                    ),
                  ],
                ),
                const SkeletonBox(
                  width: 72,
                  height: 24,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Middle: Check-In / Check-Out grid
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonText(width: 50, height: 11),
                        SizedBox(height: 6),
                        SkeletonText(width: 70, height: 18),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonText(width: 50, height: 11),
                        SizedBox(height: 6),
                        SkeletonText(width: 70, height: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Bottom: Work Location info
            Row(
              children: const [
                SkeletonBox.circle(size: 16),
                SizedBox(width: 8),
                SkeletonText(width: 120, height: 12),
                Spacer(),
                SkeletonText(width: 60, height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer list showing multiple HistoryCardSkeletons
class HistoryListSkeleton extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry? padding;

  const HistoryListSkeleton({super.key, this.itemCount = 4, this.padding});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) => const HistoryCardSkeleton(),
    );
  }
}
