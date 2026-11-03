import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'forgot_password_banners.dart';

class ForgotPasswordResetStep extends StatefulWidget {
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final FocusNode newPasswordFocus;
  final FocusNode confirmPasswordFocus;
  final bool isResetFormValid;
  final bool hasMinLength;
  final bool hasMixedCase;
  final bool hasNumber;
  final bool isPasswordMatching;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onSubmit;

  const ForgotPasswordResetStep({
    super.key,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.newPasswordFocus,
    required this.confirmPasswordFocus,
    required this.isResetFormValid,
    required this.hasMinLength,
    required this.hasMixedCase,
    required this.hasNumber,
    required this.isPasswordMatching,
    required this.isLoading,
    this.errorMessage,
    required this.onSubmit,
  });

  @override
  State<ForgotPasswordResetStep> createState() => _ForgotPasswordResetStepState();
}

class _ForgotPasswordResetStepState extends State<ForgotPasswordResetStep> {
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Widget _buildRequirementRow(String text, bool isSatisfied) {
    return Row(
      children: [
        Icon(
          isSatisfied ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 16,
          color: isSatisfied ? AppColors.success : const Color(0xFFC7C7CC),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isSatisfied
                ? const Color(0xFF1F2937)
                : const Color(0xFF6B7280),
            fontWeight: isSatisfied ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('step_3'),
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
              Icons.lock_outline_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Buat Kata Sandi Baru',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 8),

        const Text(
          'Silakan tentukan kata sandi baru untuk mengamankan akun Anda.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
        ),
        const SizedBox(height: 20),

        if (widget.errorMessage != null) ...[
          ForgotPasswordBanners.buildErrorBanner(widget.errorMessage!),
          const SizedBox(height: 16),
        ],

        // Field 1: Kata Sandi Baru
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kata Sandi Baru',
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
                  color: widget.newPasswordFocus.hasFocus
                      ? AppColors.primary
                      : const Color(0xFFE5E7EB),
                  width: widget.newPasswordFocus.hasFocus ? 1.5 : 1.0,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.newPasswordController,
                      focusNode: widget.newPasswordFocus,
                      obscureText: !_isNewPasswordVisible,
                      cursorColor: AppColors.primary,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1F2937),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Minimal 8 karakter',
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
                        widget.confirmPasswordFocus.requestFocus();
                      },
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isNewPasswordVisible = !_isNewPasswordVisible;
                      });
                    },
                    child: Icon(
                      _isNewPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: const Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Field 2: Konfirmasi Kata Sandi Baru
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Konfirmasi Kata Sandi Baru',
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
                  color: widget.confirmPasswordFocus.hasFocus
                      ? AppColors.primary
                      : const Color(0xFFE5E7EB),
                  width: widget.confirmPasswordFocus.hasFocus ? 1.5 : 1.0,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.confirmPasswordController,
                      focusNode: widget.confirmPasswordFocus,
                      obscureText: !_isConfirmPasswordVisible,
                      cursorColor: AppColors.primary,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1F2937),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Ketik ulang kata sandi baru',
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
                        if (widget.isResetFormValid && !widget.isLoading) {
                          widget.onSubmit();
                        }
                      },
                    ),
                  ),
                  if (widget.isPasswordMatching) ...[
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                  ],
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                    child: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: const Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Requirements Checklist Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              _buildRequirementRow('Minimal 8 karakter', widget.hasMinLength),
              const SizedBox(height: 8),
              _buildRequirementRow(
                'Kombinasi huruf besar & huruf kecil',
                widget.hasMixedCase,
              ),
              const SizedBox(height: 8),
              _buildRequirementRow('Mengandung minimal 1 angka', widget.hasNumber),
              const SizedBox(height: 8),
              _buildRequirementRow(
                'Konfirmasi kata sandi cocok',
                widget.isPasswordMatching,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Perbarui Kata Sandi Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: widget.isResetFormValid && !widget.isLoading
                  ? AppColors.primary
                  : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
              boxShadow: widget.isResetFormValid && !widget.isLoading
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
                onTap: widget.isResetFormValid && !widget.isLoading
                    ? widget.onSubmit
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Perbarui Kata Sandi',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

