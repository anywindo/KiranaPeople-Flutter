import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ForgotPasswordSuccessDialog extends StatelessWidget {
  final String email;
  final String message;
  final VoidCallback onLoginNow;

  const ForgotPasswordSuccessDialog({
    super.key,
    required this.email,
    required this.message,
    required this.onLoginNow,
  });

  static Future<void> show(
    BuildContext context, {
    required String email,
    required String message,
    required VoidCallback onLoginNow,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ForgotPasswordSuccessDialog(
        email: email,
        message: message,
        onLoginNow: onLoginNow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Berhasil',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Text(
        message.isNotEmpty ? message : 'Kata sandi Anda berhasil diperbarui. Silakan masuk menggunakan kata sandi baru.',
        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              onLoginNow();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Masuk Sekarang',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}
