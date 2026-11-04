import 'package:flutter/material.dart';

import '../../../data/models/attendance_event_model.dart';

class CameraTopBar extends StatelessWidget {
  final AttendanceEventType action;
  final Color textColor;
  final VoidCallback onBack;

  const CameraTopBar({
    super.key,
    required this.action,
    required this.textColor,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left_rounded,
              color: textColor,
              size: 28,
            ),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              action.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 48), // Spacer to balance back button
        ],
      ),
    );
  }
}

