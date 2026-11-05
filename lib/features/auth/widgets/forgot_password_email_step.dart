import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'forgot_password_banners.dart';

class ForgotPasswordEmailStep extends StatelessWidget {
  final TextEditingController emailController;
  final FocusNode emailFocus;
  final bool isEmailValid;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onSubmit;
  final VoidCallback onAlreadyHaveOtpTap;

  const ForgotPasswordEmailStep({
    super.key,
    required this.emailController,
    required this.emailFocus,
    required this.isEmailValid,
    required this.isLoading,
    this.errorMessage,
    required this.onSubmit,
    required this.onAlreadyHaveOtpTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('step_1'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),

        // Circular Pink Badge
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.mark_email_read_outlined,
              size: 32,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Masukkan Email Akun',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 8),

        const Text(
          'Kami akan mengirimkan 6 digit kode OTP ke alamat email terdaftar untuk memverifikasi permintaan reset kata sandi Anda.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93), height: 1.4),
        ),
        const SizedBox(height: 24),

        if (errorMessage != null) ...[
          ForgotPasswordBanners.buildErrorBanner(errorMessage!),
          const SizedBox(height: 16),
        ],

        // Email Field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alamat Email',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: emailFocus.hasFocus
                      ? AppColors.primary
                      : const Color(0xFFE5E7EB),
                  width: emailFocus.hasFocus ? 1.5 : 1.0,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.email_outlined,
                    size: 18,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      key: const Key('email_text_field'),
                      controller: emailController,
                      focusNode: emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      cursorColor: AppColors.primary,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1F2937),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'nama@kiranagroup.com',
                        hintStyle: TextStyle(
                          color: Color(0xFFC7C7CC),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                        isDense: true,
                      ),
                      onSubmitted: (_) {
                        if (isEmailValid && !isLoading) {
                          onSubmit();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Kirim Kode OTP Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isEmailValid && !isLoading
                  ? AppColors.primary
                  : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isEmailValid && !isLoading
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isEmailValid && !isLoading ? onSubmit : null,
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.send_rounded,
                              size: 16,
                              color: isEmailValid
                                  ? Colors.white
                                  : const Color(0xFF9CA3AF),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Kirim Kode OTP',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isEmailValid
                                    ? Colors.white
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Option to skip directly to entering OTP
        InkWell(
          onTap: onAlreadyHaveOtpTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Sudah punya kode OTP? Masukkan Kode',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
