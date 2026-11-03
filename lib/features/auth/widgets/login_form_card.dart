import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class LoginFormCard extends StatelessWidget {
  final TextEditingController identifierController;
  final TextEditingController passwordController;
  final FocusNode identifierFocus;
  final FocusNode passwordFocus;
  final bool isPasswordVisible;
  final bool rememberMe;
  final bool isFormValid;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onTogglePasswordVisibility;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback onForgotPasswordTap;
  final VoidCallback onSubmit;

  const LoginFormCard({
    super.key,
    required this.identifierController,
    required this.passwordController,
    required this.identifierFocus,
    required this.passwordFocus,
    required this.isPasswordVisible,
    required this.rememberMe,
    required this.isFormValid,
    required this.isLoading,
    this.errorMessage,
    required this.onTogglePasswordVisibility,
    required this.onRememberMeChanged,
    required this.onForgotPasswordTap,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: context.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: context.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error message banner if any
            if (errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.30),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Field 1: Email / ID Karyawan / NIK
            TextField(
              controller: identifierController,
              focusNode: identifierFocus,
              cursorColor: AppColors.primary,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: context.textPrimaryColor,
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                FocusScope.of(context).requestFocus(passwordFocus);
              },
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Email / ID Karyawan / NIK',
                hintText: 'Masukkan email, ID, atau NIK',
                labelStyle: TextStyle(
                  color: identifierFocus.hasFocus
                      ? AppColors.primary
                      : context.textSecondaryColor,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.badge_outlined,
                  size: 20,
                  color: identifierFocus.hasFocus
                      ? AppColors.primary
                      : context.textMutedColor,
                ),
                suffixIcon: identifierController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.cancel_rounded,
                          size: 18,
                          color: context.textMutedColor,
                        ),
                        onPressed: () {
                          identifierController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? AppColors.darkBackground.withValues(alpha: 0.5)
                    : AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Field 2: Kata Sandi
            TextField(
              controller: passwordController,
              focusNode: passwordFocus,
              obscureText: !isPasswordVisible,
              cursorColor: AppColors.primary,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: context.textPrimaryColor,
              ),
              decoration: InputDecoration(
                labelText: 'Kata Sandi',
                hintText: 'Masukkan kata sandi',
                labelStyle: TextStyle(
                  color: passwordFocus.hasFocus
                      ? AppColors.primary
                      : context.textSecondaryColor,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
                  color: passwordFocus.hasFocus
                      ? AppColors.primary
                      : context.textMutedColor,
                ),
                suffixIcon: IconButton(
                  tooltip: isPasswordVisible
                      ? 'Sembunyikan sandi'
                      : 'Tampilkan sandi',
                  onPressed: onTogglePasswordVisibility,
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: context.textMutedColor,
                  ),
                ),
                filled: true,
                fillColor: isDark
                    ? AppColors.darkBackground.withValues(alpha: 0.5)
                    : AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Options Row: Checkbox (Ingat Saya) + TextButton (Lupa Kata Sandi?)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => onRememberMeChanged(!rememberMe),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: rememberMe,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            side: BorderSide(
                              color: context.textMutedColor,
                              width: 1.5,
                            ),
                            onChanged: onRememberMeChanged,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ingat Saya',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onForgotPasswordTap,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Lupa Kata Sandi?',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // FilledButton (Masuk)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: isFormValid && !isLoading ? onSubmit : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark
                      ? AppColors.darkSurfaceSecondary
                      : const Color(0xFFE5E7EB),
                  disabledForegroundColor: isDark
                      ? AppColors.darkTextMuted
                      : const Color(0xFF9CA3AF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Masuk'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

