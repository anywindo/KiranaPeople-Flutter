import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import 'forgot_password_banners.dart';

class ForgotPasswordOtpStep extends StatelessWidget {
  final String email;
  final TextEditingController otpController;
  final FocusNode otpFocus;
  final bool isOtpValid;
  final bool isLoading;
  final String? errorMessage;
  final String? successBannerMessage;
  final int resendCooldown;
  final VoidCallback onResendOtp;
  final VoidCallback onProceed;
  final VoidCallback onChangeEmailTap;

  const ForgotPasswordOtpStep({
    super.key,
    required this.email,
    required this.otpController,
    required this.otpFocus,
    required this.isOtpValid,
    required this.isLoading,
    this.errorMessage,
    this.successBannerMessage,
    required this.resendCooldown,
    required this.onResendOtp,
    required this.onProceed,
    required this.onChangeEmailTap,
  });

  Widget _buildOtpBoxes() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Invisible input field catching keyboard input
        Opacity(
          opacity: 0.01,
          child: TextField(
            key: const Key('otp_text_field'),
            controller: otpController,
            focusNode: otpFocus,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            autofocus: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),

        // Visual 6 digit boxes
        GestureDetector(
          onTap: () {
            otpFocus.requestFocus();
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              final otpText = otpController.text;
              final char = index < otpText.length ? otpText[index] : '';
              final isFocused =
                  otpFocus.hasFocus &&
                  (otpText.length == index ||
                      (index == 5 && otpText.length == 6));

              return Container(
                width: 48,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFocused
                        ? AppColors.primary
                        : const Color(0xFFE5E7EB),
                    width: isFocused ? 2.0 : 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  char,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: Color(0xFF1C1C1E),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('step_2'),
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
              Icons.shield_outlined,
              size: 32,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Masukkan Kode OTP',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 8),

        Column(
          children: [
            const Text(
              'Kode verifikasi 6 digit telah dikirim ke:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
            ),
            const SizedBox(height: 2),
            Text(
              email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Green Success Banner
        if (successBannerMessage != null) ...[
          ForgotPasswordBanners.buildSuccessBanner(successBannerMessage!),
          const SizedBox(height: 16),
        ],

        if (errorMessage != null) ...[
          ForgotPasswordBanners.buildErrorBanner(errorMessage!),
          const SizedBox(height: 16),
        ],

        // OTP Label + Resend Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Kode OTP (6 Digit)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            if (resendCooldown > 0)
              Text(
                'Kirim ulang (${resendCooldown}s)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9CA3AF),
                ),
              )
            else
              InkWell(
                onTap: isLoading ? null : onResendOtp,
                borderRadius: BorderRadius.circular(4),
                child: const Text(
                  'Kirim Ulang OTP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // 6-digit visual boxes with hidden TextField
        _buildOtpBoxes(),
        const SizedBox(height: 24),

        // Lanjutkan Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isOtpValid && !isLoading
                  ? AppColors.primary
                  : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isOtpValid && !isLoading
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
                onTap: isOtpValid && !isLoading ? onProceed : null,
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Lanjutkan',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isOtpValid
                                    ? Colors.white
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: isOtpValid
                                  ? Colors.white
                                  : const Color(0xFF9CA3AF),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Change Email Option
        InkWell(
          onTap: onChangeEmailTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Salah alamat email? Ubah Email',
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
