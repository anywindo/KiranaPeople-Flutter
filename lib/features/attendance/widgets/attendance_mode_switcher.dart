import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

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
    return Container(
      height: 48,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.surfaceSecondaryColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Smooth Spring Capsule Pill
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: activeSegment == 0
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
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
                      HapticFeedback.selectionClick();
                      onSegmentChanged(0);
                    }
                  },
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.work_rounded,
                          size: 16,
                          color: activeSegment == 0
                              ? Colors.white
                              : context.textSecondaryColor,
                        ),
                        const SizedBox(width: 6),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
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
                      HapticFeedback.selectionClick();
                      onSegmentChanged(1);
                    }
                  },
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.coffee_rounded,
                          size: 16,
                          color: activeSegment == 1
                              ? Colors.white
                              : context.textSecondaryColor,
                        ),
                        const SizedBox(width: 6),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
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
