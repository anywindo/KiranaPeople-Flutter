import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_haptics.dart';

class AttendanceModeSwitcher extends StatelessWidget {
  final int activeSegment; // 0 = Kerja, 1 = Istirahat
  final ValueChanged<int> onSegmentChanged;

  const AttendanceModeSwitcher({
    super.key,
    required this.activeSegment,
    required this.onSegmentChanged,
  });

  @override
  Widget build(BuildContext context) {
    const animationDuration = Duration(milliseconds: 250);
    const animationCurve = Curves.easeOutCubic;

    return Container(
      height: 48,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? const Color(0xFF1E293B)
            : const Color(0xFFEEF2F6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.isDarkMode
              ? const Color(0xFF334155).withValues(alpha: 0.6)
              : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Smooth Spring Capsule Pill
          AnimatedAlign(
            duration: animationDuration,
            curve: animationCurve,
            alignment: activeSegment == 0
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFF2A88),
                      Color(0xFFE6007A),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1,
                  ),
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
                  onTap: () {
                    if (activeSegment != 0) {
                      AppHaptics.selection();
                      onSegmentChanged(0);
                    }
                  },
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<Color?>(
                          duration: animationDuration,
                          curve: animationCurve,
                          tween: ColorTween(
                            end: activeSegment == 0
                                ? Colors.white
                                : context.textSecondaryColor,
                          ),
                          builder: (context, color, _) {
                            return Icon(
                              Icons.work_rounded,
                              size: 16,
                              color: color,
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        AnimatedDefaultTextStyle(
                          duration: animationDuration,
                          curve: animationCurve,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: activeSegment == 0
                                ? Colors.white
                                : context.textSecondaryColor,
                          ),
                          child: const Text('Kerja'),
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
                  onTap: () {
                    if (activeSegment != 1) {
                      AppHaptics.selection();
                      onSegmentChanged(1);
                    }
                  },
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<Color?>(
                          duration: animationDuration,
                          curve: animationCurve,
                          tween: ColorTween(
                            end: activeSegment == 1
                                ? Colors.white
                                : context.textSecondaryColor,
                          ),
                          builder: (context, color, _) {
                            return Icon(
                              Icons.coffee_rounded,
                              size: 16,
                              color: color,
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        AnimatedDefaultTextStyle(
                          duration: animationDuration,
                          curve: animationCurve,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: activeSegment == 1
                                ? Colors.white
                                : context.textSecondaryColor,
                          ),
                          child: const Text('Istirahat'),
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
    );
  }
}
