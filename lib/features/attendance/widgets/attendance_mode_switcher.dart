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
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.isDarkMode
              ? [
                  const Color(0xFF13151C),
                  const Color(0xFF1B1D26),
                ]
              : [
                  const Color(0xFFE2E7ED),
                  const Color(0xFFEDF1F6),
                ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: context.isDarkMode
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFD6DCE5),
          width: 1.0,
        ),
        boxShadow: [
          // Sunken channel shadow
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.35 : 0.06,
            ),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
          // Bottom groove reflection
          BoxShadow(
            color: Colors.white.withValues(
              alpha: context.isDarkMode ? 0.05 : 0.85,
            ),
            blurRadius: 0,
            spreadRadius: 0.5,
            offset: const Offset(0, 1),
          ),
        ],
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
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFF337E), // top highlight
                      AppColors.primary,
                      Color(0xFFD80052), // bottom bevel
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.32),
                    width: 1.0,
                  ),
                  boxShadow: [
                    // Specular rim
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.35),
                      blurRadius: 1,
                      offset: const Offset(0, -1),
                    ),
                    // Contact shadow
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                    // Ambient colorful glow
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
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
