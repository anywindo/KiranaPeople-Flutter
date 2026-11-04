import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../privacy_policy_sheet.dart';

class OnboardingPolicyAgreement extends StatelessWidget {
  final bool hasAcceptedPolicies;
  final ValueChanged<bool> onChanged;

  const OnboardingPolicyAgreement({
    super.key,
    required this.hasAcceptedPolicies,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: hasAcceptedPolicies,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            onChanged: (val) => onChanged(val ?? false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () {
              PrivacyPolicySheet.show(
                context,
                onAccept: () => onChanged(true),
              );
            },
            child: RichText(
              text: const TextSpan(
                text: 'Saya telah membaca dan menyetujui ',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4B5563),
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: 'Kebijakan Privasi & Ketentuan Layanan',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

