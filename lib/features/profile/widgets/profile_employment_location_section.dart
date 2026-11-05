import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/continuous_marquee_text.dart';
import 'profile_card_group.dart';

class ProfileEmploymentLocationSection extends StatelessWidget {
  final String employeeId;
  final String roleName;
  final String officeName;
  final String radiusStr;
  final String joinedStr;
  final void Function(String text, String label) onCopy;

  const ProfileEmploymentLocationSection({
    super.key,
    required this.employeeId,
    required this.roleName,
    required this.officeName,
    required this.radiusStr,
    required this.joinedStr,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionHeader(title: 'DATA KEPEGAWAIAN & LOKASI'),
        ProfileCardGroup(
          children: [
            ProfileRowItem(
              iconBg: context.isDarkMode
                  ? const Color(0xFF3B1524)
                  : const Color(0xFFFFF1F5),
              icon: Icons.badge_rounded,
              iconColor: AppColors.primary,
              title: 'ID Karyawan',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    employeeId,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => onCopy(employeeId, 'ID Karyawan'),
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
              icon: Icons.work_rounded,
              iconColor: AppColors.primary,
              title: 'Jabatan',
              trailing: Text(
                roleName,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondaryColor,
                ),
              ),
            ),
            Divider(height: 1, indent: 56, color: context.dividerColor),
            ProfileRowItem(
              iconBg: context.isDarkMode
                  ? const Color(0xFF3B1524)
                  : const Color(0xFFFFF1F5),
              icon: Icons.apartment_rounded,
              iconColor: AppColors.primary,
              title: 'Lokasi Kantor',
              isTrailingExpanded: true,
              trailing: ContinuousMarqueeText(
                text: officeName,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondaryColor,
                ),
              ),
            ),
            Divider(height: 1, indent: 56, color: context.dividerColor),
            ProfileRowItem(
              iconBg: context.isDarkMode
                  ? const Color(0xFF3B1524)
                  : const Color(0xFFFFF1F5),
              icon: Icons.near_me_rounded,
              iconColor: AppColors.primary,
              title: 'Radius Presensi',
              trailing: Text(
                radiusStr,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondaryColor,
                ),
              ),
            ),
            Divider(height: 1, indent: 56, color: context.dividerColor),
            ProfileRowItem(
              iconBg: context.isDarkMode
                  ? const Color(0xFF3B1524)
                  : const Color(0xFFFFF1F5),
              icon: Icons.calendar_month_rounded,
              iconColor: AppColors.primary,
              title: 'Bergabung',
              trailing: Text(
                joinedStr,
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
