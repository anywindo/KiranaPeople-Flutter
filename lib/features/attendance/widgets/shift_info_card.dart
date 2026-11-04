import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/attendance_event_model.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/shift_model.dart';
import 'shift/shift_break_panel.dart';
import 'shift/shift_card_header.dart';
import 'shift/shift_work_panel.dart';

export 'shift/shift_break_panel.dart';
export 'shift/shift_card_header.dart';
export 'shift/shift_work_panel.dart';

class ShiftInfoCard extends StatelessWidget {
  final int activeSegment; // 0 = Kerja, 1 = Istirahat
  final Shift? selectedShift;
  final TodayAttendanceData? todayData;
  final bool isSubmitting;
  final bool hasStartedShift;
  final bool isCheckInLate;
  final bool hasEndedShift;
  final bool hasStartedBreak;
  final bool hasEndedBreak;
  final String? checkInTime;
  final String? checkOutTime;
  final String? startBreakTime;
  final String? endBreakTime;
  final AttendanceEvent? startShiftEvent;
  final AttendanceEvent? endShiftEvent;
  final AttendanceEvent? startBreakEvent;
  final AttendanceEvent? endBreakEvent;
  final VoidCallback onPickShift;
  final VoidCallback onSwitchToWork;
  final Widget actionButton;

  const ShiftInfoCard({
    super.key,
    required this.activeSegment,
    required this.selectedShift,
    required this.todayData,
    required this.isSubmitting,
    required this.hasStartedShift,
    required this.isCheckInLate,
    required this.hasEndedShift,
    required this.hasStartedBreak,
    required this.hasEndedBreak,
    required this.checkInTime,
    required this.checkOutTime,
    required this.startBreakTime,
    required this.endBreakTime,
    required this.startShiftEvent,
    required this.endShiftEvent,
    required this.startBreakEvent,
    required this.endBreakEvent,
    required this.onPickShift,
    required this.onSwitchToWork,
    required this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.isDarkMode
              ? [
                  const Color(0xFF282C37),
                  const Color(0xFF20232D),
                  const Color(0xFF191B22),
                ]
              : [
                  const Color(0xFFFFFFFF),
                  const Color(0xFFFAFBFC),
                  const Color(0xFFF3F5F9),
                ],
          stops: const [0.0, 0.45, 1.0],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: context.isDarkMode
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          // 1. Top specular rim (overhead ambient bounce highlight)
          BoxShadow(
            color: Colors.white.withValues(
              alpha: context.isDarkMode ? 0.08 : 0.95,
            ),
            blurRadius: 0,
            spreadRadius: 1,
            offset: const Offset(0, -1),
          ),
          // 2. Direct crisp drop shadow
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.35 : 0.04,
            ),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
          // 3. Ambient deep shadow for physical elevation
          BoxShadow(
            color: (context.isDarkMode ? Colors.black : const Color(0xFF0F172A))
                .withValues(
              alpha: context.isDarkMode ? 0.50 : 0.07,
            ),
            blurRadius: 18,
            spreadRadius: -2,
            offset: const Offset(0, 9),
          ),
          // 4. Subtle chromatic glow underneath
          BoxShadow(
            color: AppColors.primary.withValues(
              alpha: context.isDarkMode ? 0.04 : 0.015,
            ),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle & Sync Indicator
          ShiftCardHeader(isSubmitting: isSubmitting),
          const SizedBox(height: 12),

          // Shift Panels with Smooth Crossfade/Slide Animation
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.topCenter,
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              transitionBuilder: (child, animation) {
                final isKerja = (child.key as ValueKey<int>?)?.value == 0;
                final beginOffset = isKerja
                    ? const Offset(-0.06, 0.0)
                    : const Offset(0.06, 0.0);
                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  ),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: beginOffset,
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(activeSegment),
                child: activeSegment == 0
                    ? ShiftWorkPanel(
                        selectedShift: selectedShift,
                        todayData: todayData,
                        hasStartedShift: hasStartedShift,
                        isCheckInLate: isCheckInLate,
                        hasEndedShift: hasEndedShift,
                        checkInTime: checkInTime,
                        checkOutTime: checkOutTime,
                        startShiftEvent: startShiftEvent,
                        endShiftEvent: endShiftEvent,
                        onPickShift: onPickShift,
                      )
                    : ShiftBreakPanel(
                        selectedShift: selectedShift,
                        hasStartedShift: hasStartedShift,
                        hasStartedBreak: hasStartedBreak,
                        hasEndedBreak: hasEndedBreak,
                        hasEndedShift: hasEndedShift,
                        startBreakTime: startBreakTime,
                        endBreakTime: endBreakTime,
                        startBreakEvent: startBreakEvent,
                        endBreakEvent: endBreakEvent,
                        onSwitchToWork: onSwitchToWork,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Big Action Button
          actionButton,
        ],
      ),
    );
  }
}
