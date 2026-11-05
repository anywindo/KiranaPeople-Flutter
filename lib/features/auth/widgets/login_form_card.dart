import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bouncing_button.dart';

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

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
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
                  fontWeight: identifierFocus.hasFocus
                      ? FontWeight.w600
                      : FontWeight.w400,
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
                fillColor: identifierFocus.hasFocus
                    ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                    : (isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9)),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  borderSide: BorderSide(color: AppColors.primary, width: 2.2),
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
                  fontWeight: passwordFocus.hasFocus
                      ? FontWeight.w600
                      : FontWeight.w400,
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
                    color: passwordFocus.hasFocus
                        ? AppColors.primary
                        : context.textMutedColor,
                  ),
                ),
                filled: true,
                fillColor: passwordFocus.hasFocus
                    ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                    : (isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9)),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  borderSide: BorderSide(color: AppColors.primary, width: 2.2),
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

            // Button (Masuk)
            BouncingButton(
              scaleDown: 0.97,
              hapticType: BouncingHapticType.medium,
              onPressed: isFormValid && !isLoading ? onSubmit : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isFormValid && !isLoading
                      ? AppColors.primary
                      : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0)),
                  border: isFormValid && !isLoading
                      ? Border.all(color: const Color(0xFFDB2777), width: 1.2)
                      : Border.all(
                          color: isDark
                              ? const Color(0xFF475569)
                              : const Color(0xFFCBD5E1),
                          width: 1.0,
                        ),
                  boxShadow: isFormValid && !isLoading
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.45 : 0.16,
                            ),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.25 : 0.08,
                            ),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Masuk',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: isFormValid && !isLoading
                                ? Colors.white
                                : (isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF9CA3AF)),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
