import 'package:flutter/material.dart';

import '../shimmer_loading.dart';

/// Shimmer for Profile Screen Header
class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: const [
          SkeletonBox.circle(size: 88),
          SizedBox(height: 14),
          SkeletonText(width: 160, height: 20),
          SizedBox(height: 8),
          SkeletonText(width: 180, height: 13),
          SizedBox(height: 10),
          SkeletonBox(
            width: 100,
            height: 24,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ],
      ),
    );
  }
}
