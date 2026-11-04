import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_haptics.dart';
import 'models/privacy_policy_data.dart';
import 'widgets/privacy_policy_highlights_banner.dart';
import 'widgets/privacy_policy_section_card.dart';

export 'models/privacy_policy_data.dart';
export 'widgets/privacy_policy_highlights_banner.dart';
export 'widgets/privacy_policy_section_card.dart';

class PrivacyPolicySheet extends StatelessWidget {
  final VoidCallback? onAccept;

  const PrivacyPolicySheet({super.key, this.onAccept});

  static Future<void> show(BuildContext context, {VoidCallback? onAccept}) {
    AppHaptics.light();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PrivacyPolicySheet(onAccept: onAccept),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final maxHeight = MediaQuery.of(context).size.height * 0.90;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.20 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kebijakan Privasi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Kirana People · PT Kirana Desain Indonesia',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: context.textSecondaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'UU PDP No. 27/2022',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    AppHaptics.light();
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: context.textMutedColor,
                    size: 22,
                  ),
                  tooltip: 'Tutup',
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.borderColor),

          // Scrollable Content
          Expanded(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Quick Highlights Banner
                const PrivacyPolicyHighlightsBanner(),
                const SizedBox(height: 20),

                // 12 Sections
                ...privacySections.map((section) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: PrivacyPolicySectionCard(section: section),
                  );
                }),
                const SizedBox(height: 6),

                // Footer version note
                Center(
                  child: Text(
                    'Terakhir diperbarui: 3 November 2026 · Versi 2.0 (Lengkap & Terverifikasi)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textMutedColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Bottom Action
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(top: BorderSide(color: context.borderColor)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  AppHaptics.medium();
                  Navigator.pop(context);
                  onAccept?.call();
                },
                child: Text(
                  onAccept != null
                      ? 'Saya Telah Membaca & Menyetujui'
                      : 'Saya Mengerti & Tutup',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
