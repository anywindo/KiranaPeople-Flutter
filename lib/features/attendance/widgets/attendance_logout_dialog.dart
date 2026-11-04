import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class AttendanceLogoutDialog extends StatelessWidget {
  final VoidCallback onConfirmLogout;

  const AttendanceLogoutDialog({
    super.key,
    required this.onConfirmLogout,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onConfirmLogout,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AttendanceLogoutDialog(
        onConfirmLogout: onConfirmLogout,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text(
        'Keluar Akun',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Batal',
            style: TextStyle(color: Color(0xFF8E8E93)),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            Navigator.of(
              context,
              rootNavigator: true,
            ).popUntil((route) => route.isFirst);
            onConfirmLogout();
          },
          child: const Text('Keluar'),
        ),
      ],
    );
  }
}

