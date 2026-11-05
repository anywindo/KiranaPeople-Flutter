import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_haptics.dart';

class AttendanceModeSwitcher extends StatefulWidget {
  final int activeSegment; // 0 = Kerja, 1 = Istirahat
  final ValueChanged<int> onSegmentChanged;

  const AttendanceModeSwitcher({
    super.key,
    required this.activeSegment,
    required this.onSegmentChanged,
  });

  @override
  State<AttendanceModeSwitcher> createState() => _AttendanceModeSwitcherState();
}

class _AttendanceModeSwitcherState extends State<AttendanceModeSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 250),
          value: widget.activeSegment.toDouble(),
        )..addListener(() {
          setState(() {});
        });
  }

  @override
  void didUpdateWidget(AttendanceModeSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging && widget.activeSegment != oldWidget.activeSegment) {
      _controller.animateTo(
        widget.activeSegment.toDouble(),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectSegment(int target) {
    if (widget.activeSegment != target) {
      AppHaptics.selection();
      widget.onSegmentChanged(target);
    }
    _controller.animateTo(
      target.toDouble(),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleDragStart(DragStartDetails details) {
    _isDragging = true;
  }

  void _handleDragUpdate(DragUpdateDetails details, double totalWidth) {
    final trackWidth = totalWidth - 8.0;
    final maxTravelDistance = trackWidth / 2.0;
    if (maxTravelDistance > 0) {
      _controller.value =
          (_controller.value + details.primaryDelta! / maxTravelDistance).clamp(
            0.0,
            1.0,
          );
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    _isDragging = false;
    final velocity = details.primaryVelocity ?? 0.0;
    int target;
    if (velocity > 300) {
      target = 1;
    } else if (velocity < -300) {
      target = 0;
    } else {
      target = _controller.value >= 0.5 ? 1 : 0;
    }

    _controller.animateTo(
      target.toDouble(),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );

    if (target != widget.activeSegment) {
      AppHaptics.selection();
      widget.onSegmentChanged(target);
    }
  }

  void _handleDragCancel() {
    _isDragging = false;
    _controller.animateTo(
      widget.activeSegment.toDouble(),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _controller.value;
    final isDark = context.isDarkMode;

    final unselectedColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF475569);
    final kerjaColor =
        Color.lerp(Colors.white, unselectedColor, t) ?? Colors.white;
    final istirahatColor =
        Color.lerp(unselectedColor, Colors.white, t) ?? Colors.white;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _handleDragStart,
          onHorizontalDragUpdate: (details) =>
              _handleDragUpdate(details, constraints.maxWidth),
          onHorizontalDragEnd: _handleDragEnd,
          onHorizontalDragCancel: _handleDragCancel,
          onTapUp: (details) {
            final target = details.localPosition.dx < constraints.maxWidth / 2
                ? 0
                : 1;
            _selectSegment(target);
          },
          child: Container(
            height: 48,
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFDCE2ED),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.antiAlias,
              children: [
                // Draggable Smooth Capsule Pill
                Align(
                  alignment: Alignment(-1.0 + 2.0 * t, 0.0),
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    heightFactor: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.35 : 0.12,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Touch Targets & Labels
                Row(
                  children: [
                    // Kerja Tab
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _selectSegment(0),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.work_rounded,
                                size: 16,
                                color: kerjaColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Kerja',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: kerjaColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Istirahat Tab
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _selectSegment(1),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.coffee_rounded,
                                size: 16,
                                color: istirahatColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Istirahat',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: istirahatColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
