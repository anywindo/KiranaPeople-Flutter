import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'profile_card_group.dart';

class ProfileAccountSecuritySection extends StatelessWidget {
  final String phoneStr;
  final String userEmail;
  final VoidCallback onPhoneTap;
  final VoidCallback onChangePasswordTap;
  final void Function(String text, String label) onCopy;

  const ProfileAccountSecuritySection({
    super.key,
    required this.phoneStr,
    required this.userEmail,
    required this.onPhoneTap,
    required this.onChangePasswordTap,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionHeader(title: 'PENGATURAN AKUN & KEAMANAN'),
        ProfileCardGroup(
          children: [
            ProfileRowItem(
              iconBg: context.isDarkMode
                  ? const Color(0xFF3B1524)
                  : const Color(0xFFFFF1F5),
              icon: Icons.phone_rounded,
              iconColor: AppColors.primary,
              title: 'Nomor Telepon',
              onTap: onPhoneTap,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    phoneStr,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: context.borderColor,
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              indent: 56,
              color: context.dividerColor,
            ),
            ProfileRowItem(
              iconBg: context.isDarkMode
                  ? const Color(0xFF3B1524)
                  : const Color(0xFFFFF1F5),
              icon: Icons.shield_outlined,
              iconColor: AppColors.primary,
              title: 'Kata Sandi',
              onTap: onChangePasswordTap,
              trailing: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ubah Sandi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF2D75),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Color(0xFFFF2D75),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              indent: 56,
              color: context.dividerColor,
            ),
            ProfileRowItem(
              iconBg: context.isDarkMode
                  ? const Color(0xFF3B1524)
                  : const Color(0xFFFFF1F5),
              icon: Icons.mail_rounded,
              iconColor: AppColors.primary,
              title: 'Email',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      userEmail,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => onCopy(userEmail, 'Email'),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: context.textMutedColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

