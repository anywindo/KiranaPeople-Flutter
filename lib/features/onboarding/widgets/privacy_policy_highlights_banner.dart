import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/privacy_policy_data.dart';

class PrivacyPolicyHighlightsBanner extends StatelessWidget {
  final List<PrivacyHighlight> items;

  const PrivacyPolicyHighlightsBanner({
    super.key,
    this.items = privacyHighlights,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.30 : 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Ikhtisar Komitmen Privasi Kami',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.1,
            children: items.map((item) {
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface.withValues(alpha: 0.8)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFF1F5F9),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.icon, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.desc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5,
                              height: 1.25,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

