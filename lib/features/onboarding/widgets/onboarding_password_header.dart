import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';

class OnboardingPasswordHeader extends StatelessWidget {
  final UserModel? user;

  const OnboardingPasswordHeader({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Header Icon
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.key_rounded,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: 16),

        // Title
        const Text(
          'Aktivasi Kata Sandi',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          user != null
              ? 'Halo ${user!.name}, demi keamanan silakan buat kata sandi baru untuk akun Anda.'
              : 'Demi keamanan, silakan ganti kata sandi bawaan akun Anda.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
