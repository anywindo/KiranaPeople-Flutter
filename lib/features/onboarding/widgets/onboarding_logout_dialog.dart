import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class OnboardingLogoutDialog extends StatelessWidget {
  final VoidCallback onConfirmLogout;

  const OnboardingLogoutDialog({super.key, required this.onConfirmLogout});

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onConfirmLogout,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) =>
          OnboardingLogoutDialog(onConfirmLogout: onConfirmLogout),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Batalkan Aktivasi?',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
      ),
      content: const Text(
        'Sesi login Anda akan diakhiri dan Anda akan diarahkan kembali ke layar masuk.',
        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          onPressed: () {
            Navigator.pop(context);
            onConfirmLogout();
          },
          child: const Text('Keluar'),
        ),
      ],
    );
  }
}
