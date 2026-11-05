import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Column(
      children: [
        const SizedBox(height: 12),

        // Kirana Logo Asset (logoKiranaSquare.jpeg)
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(
              color: isDark ? const Color(0xFF475569) : const Color(0xFF1E293B),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.60 : 0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logoKiranaSquare.jpeg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.black,
                child: const Center(
                  child: Text(
                    'KIRANA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // Title & Subtitle
        Text(
          'Masuk ke Akun Anda',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: context.textPrimaryColor,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Silakan masukkan identitas dan kata sandi Anda',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: context.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}
