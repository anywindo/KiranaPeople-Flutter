import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class HistoryFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? selectedColor;
  final Color? selectedBg;
  final VoidCallback onTap;

  const HistoryFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.selectedColor,
    this.selectedBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = selectedBg ?? AppColors.primary.withValues(alpha: 0.12);
    final activeText = selectedColor ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : context.surfaceSecondaryColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeText : context.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? activeText : context.textSecondaryColor,
          ),
        ),
      ),
    );
  }
}

