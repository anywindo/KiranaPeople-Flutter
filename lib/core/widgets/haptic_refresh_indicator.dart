import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme/app_theme.dart';
import '../utils/app_haptics.dart';

/// A wrapper around [RefreshIndicator] that provides tactile haptic feedback:
/// 1. A crisp selection click ([AppHaptics.selection]) when pulling past the trigger threshold.
/// 2. A satisfying medium pulse ([AppHaptics.medium]) when refresh is committed.
class HapticRefreshIndicator extends StatefulWidget {
  final Widget child;
  final RefreshCallback onRefresh;
  final double displacement;
  final double edgeOffset;
  final Color? color;
  final Color? backgroundColor;
  final ScrollNotificationPredicate notificationPredicate;
  final double triggerThreshold;

  const HapticRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
    this.color,
    this.backgroundColor,
    this.notificationPredicate = defaultScrollNotificationPredicate,
    this.triggerThreshold = 80.0,
  });

  @override
  State<HapticRefreshIndicator> createState() => _HapticRefreshIndicatorState();
}

class _HapticRefreshIndicatorState extends State<HapticRefreshIndicator> {
  bool _hasTriggeredArmHaptic = false;
  double _accumulatedOverscroll = 0.0;

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!widget.notificationPredicate(notification)) {
      return false;
    }

    // 1. iOS / Bouncing physics: metrics.pixels becomes negative during pull-down
    if (notification is ScrollUpdateNotification) {
      if (notification.metrics.extentBefore == 0) {
        final pixels = notification.metrics.pixels;
        if (pixels <= -widget.triggerThreshold && !_hasTriggeredArmHaptic) {
          _hasTriggeredArmHaptic = true;
          AppHaptics.selection();
        } else if (pixels > -widget.triggerThreshold / 2 &&
            _hasTriggeredArmHaptic) {
          _hasTriggeredArmHaptic = false;
        }
      }
    }

    // 2. Android / Clamping physics: overscroll notifications during pull-down
    if (notification is OverscrollNotification) {
      if (notification.overscroll < 0) {
        _accumulatedOverscroll += notification.overscroll.abs();
        if (_accumulatedOverscroll >= widget.triggerThreshold &&
            !_hasTriggeredArmHaptic) {
          _hasTriggeredArmHaptic = true;
          AppHaptics.selection();
        }
      }
    }

    // 3. Reset state on scroll release / end
    if (notification is ScrollEndNotification ||
        (notification is UserScrollNotification &&
            notification.direction == ScrollDirection.idle)) {
      _hasTriggeredArmHaptic = false;
      _accumulatedOverscroll = 0.0;
    }

    return false;
  }

  Future<void> _handleRefresh() async {
    AppHaptics.medium();
    await widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      displacement: widget.displacement,
      edgeOffset: widget.edgeOffset,
      color: widget.color ?? AppColors.primary,
      backgroundColor: widget.backgroundColor,
      notificationPredicate: widget.notificationPredicate,
      onRefresh: _handleRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: widget.child,
      ),
    );
  }
}
