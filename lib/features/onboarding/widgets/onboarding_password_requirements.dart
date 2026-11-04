import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class OnboardingPasswordRequirements extends StatelessWidget {
  final bool hasMinLength;
  final bool hasMixedCase;
  final bool hasNumber;
  final bool isMatching;

  const OnboardingPasswordRequirements({
    super.key,
    required this.hasMinLength,
    required this.hasMixedCase,
    required this.hasNumber,
    required this.isMatching,
  });

  Widget _buildRequirementRow(String label, bool isSatisfied) {
    return Row(
      children: [
        Icon(
          isSatisfied ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 15,
          color: isSatisfied ? AppColors.success : const Color(0xFFD1D5DB),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSatisfied ? FontWeight.w600 : FontWeight.normal,
              color: isSatisfied
                  ? const Color(0xFF1F2937)
                  : const Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        children: [
          _buildRequirementRow('Minimal 8 karakter', hasMinLength),
          const SizedBox(height: 8),
          _buildRequirementRow(
            'Kombinasi huruf besar & huruf kecil',
            hasMixedCase,
          ),
          const SizedBox(height: 8),
          _buildRequirementRow(
            'Mengandung minimal 1 angka',
            hasNumber,
          ),
          const SizedBox(height: 8),
          _buildRequirementRow(
            'Konfirmasi kata sandi cocok',
            isMatching,
          ),
        ],
      ),
    );
  }
}

