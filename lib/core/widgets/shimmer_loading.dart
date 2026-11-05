import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';

import 'shimmers/attendance_skeletons.dart';
import 'shimmers/history_skeletons.dart';
import 'shimmers/profile_skeletons.dart';

export 'shimmers/attendance_skeletons.dart';
export 'shimmers/history_skeletons.dart';
export 'shimmers/profile_skeletons.dart';

/// Wraps child widgets with an animated shimmer effect, automatically styled
/// for both Light Mode and Dark Mode.
class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration period;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.enabled = true,
    this.baseColor,
    this.highlightColor,
    this.period = const Duration(milliseconds: 1400),
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final isDark = context.isDarkMode;
    final defaultBase = isDark
        ? const Color(0xFF1E293B) // Slate 800
        : const Color(0xFFE2E8F0); // Slate 200
    final defaultHighlight = isDark
        ? const Color(0xFF334155) // Slate 700
        : const Color(0xFFF8FAFC); // Slate 50

    return Shimmer.fromColors(
      baseColor: baseColor ?? defaultBase,
      highlightColor: highlightColor ?? defaultHighlight,
      period: period,
      child: child,
    );
  }
}

/// A basic rectangular skeleton element with rounded corners.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  const SkeletonBox.circle({super.key, required double size})
    : width = size,
      height = size,
      borderRadius = null,
      shape = BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : (borderRadius ?? BorderRadius.circular(8)),
      ),
    );
  }
}

/// A line of skeleton text with rounded corners.
class SkeletonText extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonText({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }
}
