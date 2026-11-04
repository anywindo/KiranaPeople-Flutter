import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class HistoryLocationRadiusBadge extends StatelessWidget {
  final bool isInside;
  final double distance;
  final double radius;

  const HistoryLocationRadiusBadge({
    super.key,
    required this.isInside,
    required this.distance,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: context.surfaceSecondaryColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Icon(
            isInside
                ? Icons.check_circle_rounded
                : Icons.info_outline_rounded,
            size: 15,
            color: isInside
                ? const Color(0xFF059669)
                : const Color(0xFFD97706),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              isInside
                  ? 'Dalam radius presensi (${distance.round()} m dari kantor)'
                  : 'Jarak ${distance >= 1000 ? '${(distance / 1000).toStringAsFixed(2)} km' : '${distance.round()} m'} dari titik kantor (Radius: ${radius.round()}m)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isInside
                    ? const Color(0xFF059669)
                    : const Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

