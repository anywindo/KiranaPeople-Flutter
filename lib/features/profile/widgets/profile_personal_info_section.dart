import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'profile_card_group.dart';

class ProfilePersonalInfoSection extends StatelessWidget {
  final String nikStr;
  final String dobStr;
  final void Function(String text, String label) onCopy;

  const ProfilePersonalInfoSection({
    super.key,
    required this.nikStr,
    required this.dobStr,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionHeader(title: 'IDENTITAS PRIBADI'),
        ProfileCardGroup(
          children: [
            ProfileRowItem(
              iconBg: context.isDarkMode
                  ? const Color(0xFF3B1524)
                  : const Color(0xFFFFF1F5),
              icon: Icons.credit_card_rounded,
              iconColor: AppColors.primary,
              title: 'NIK',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    nikStr,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => onCopy(nikStr, 'NIK'),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: context.textMutedColor,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, indent: 56, color: context.dividerColor),
            ProfileRowItem(
              iconBg: context.isDarkMode
                  ? const Color(0xFF3B1524)
                  : const Color(0xFFFFF1F5),
              icon: Icons.card_giftcard_rounded,
              iconColor: AppColors.primary,
              title: 'Tanggal Lahir',
              trailing: Text(
                dobStr,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondaryColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
