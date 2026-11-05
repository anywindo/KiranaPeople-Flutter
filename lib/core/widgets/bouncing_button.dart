import 'package:flutter/material.dart';

import '../utils/app_haptics.dart';

enum BouncingHapticType { none, light, medium, heavy, selection }

/// A premium tactile button wrapper that provides smooth spring scale bounce
/// and haptic feedback on touch down and release.
class BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double scaleDown;
  final Duration duration;
  final bool enableHaptics;
  final BouncingHapticType hapticType;

  const BouncingButton({
    super.key,
    required this.child,
    this.onPressed,
    this.scaleDown = 0.96,
    this.duration = const Duration(milliseconds: 120),
    this.enableHaptics = true,
    this.hapticType = BouncingHapticType.light,
  });

  @override
  State<BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<BouncingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
        reverseCurve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed == null) return;
    if (widget.enableHaptics) {
      switch (widget.hapticType) {
        case BouncingHapticType.light:
          AppHaptics.light();
          break;
        case BouncingHapticType.medium:
          AppHaptics.medium();
          break;
        case BouncingHapticType.heavy:
          AppHaptics.heavy();
          break;
        case BouncingHapticType.selection:
          AppHaptics.selection();
          break;
        case BouncingHapticType.none:
          break;
      }
    }
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed == null) return;
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    if (widget.onPressed == null) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: widget.child,
      ),
    );
  }
}
