import 'package:flutter/material.dart';

import '../../../../data/models/attendance_event_model.dart';

class ConfirmationAppBar extends StatelessWidget {
  final AttendanceEventType action;
  final VoidCallback onRetake;
  final VoidCallback onCancel;

  const ConfirmationAppBar({
    super.key,
    required this.action,
    required this.onRetake,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back / Retake button
          InkWell(
            onTap: onRetake,
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 2),
                  Text(
                    'Foto',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center Action Title
          Text(
            action.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Batal button
          TextButton(
            onPressed: onCancel,
            child: const Text(
              'Batal',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
