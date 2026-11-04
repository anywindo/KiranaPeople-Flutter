import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/privacy_policy_data.dart';

class PrivacyPolicySectionCard extends StatelessWidget {
  final PrivacyPolicySection section;

  const PrivacyPolicySectionCard({
    super.key,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.6)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.borderColor.withValues(alpha: isDark ? 0.5 : 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(section.icon, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${section.sectionNumber}. ${section.title}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (section.badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (section.badgeColor ?? AppColors.primary)
                              .withValues(alpha: isDark ? 0.25 : 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          section.badge!,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: section.badgeColor ?? AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            section.content,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: context.textSecondaryColor,
            ),
          ),
          if (section.bulletPoints != null && section.bulletPoints!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...section.bulletPoints!.map((point) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5, right: 8),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        point,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.45,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

