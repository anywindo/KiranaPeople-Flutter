import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/widgets/bouncing_button.dart';
import '../../../data/models/shift_model.dart';

class MapAttendanceActionCard extends StatelessWidget {
  final bool hasLocation;
  final String? locationError;
  final bool isInsideRadius;
  final double distance;
  final LatLng officeLatLng;
  final String officeName;
  final Shift? selectedShift;
  final bool isActionDisabled;
  final String actionBtnLabel;
  final VoidCallback onAction;

  const MapAttendanceActionCard({
    super.key,
    required this.hasLocation,
    this.locationError,
    required this.isInsideRadius,
    required this.distance,
    required this.officeLatLng,
    required this.officeName,
    this.selectedShift,
    required this.isActionDisabled,
    required this.actionBtnLabel,
    required this.onAction,
  });

  String _formatShortTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '--:--';
    if (timeStr.length >= 5) {
      return timeStr.substring(0, 5);
    }
    return timeStr;
  }

  Future<void> _launchRoute() async {
    AppHaptics.light();
    final lat = officeLatLng.latitude;
    final lng = officeLatLng.longitude;
    final googleMapsAppUri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($officeName)');
    final webMapsUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );

    try {
      // 1. Try native navigation intent if available
      if (await canLaunchUrl(googleMapsAppUri)) {
        await launchUrl(googleMapsAppUri);
        return;
      }
      // 2. Try geo URI scheme
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri);
        return;
      }
      // 3. Fallback to Google Maps URL (External App first, then Browser)
      final launched = await launchUrl(
        webMapsUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(webMapsUri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      try {
        await launchUrl(
          webMapsUri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
      } catch (_) {
        await launchUrl(webMapsUri, mode: LaunchMode.platformDefault);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    final Color statusColor;
    final String statusTitle;
    final String statusSubtitle;

    if (!hasLocation) {
      statusColor = const Color(0xFFF59E0B);
      statusTitle = locationError ?? 'Mencari Lokasi GPS...';
      statusSubtitle = 'Ketuk tombol refresh untuk memuat koordinat';
    } else if (isInsideRadius) {
      statusColor = const Color(0xFF10B981);
      statusTitle = 'Dalam Radius Presensi';
      statusSubtitle = '${distance.round()} m dari titik kantor';
    } else {
      statusColor = const Color(0xFFEF4444);
      statusTitle = 'Di Luar Radius Presensi';
      statusSubtitle = '${distance.round()} m dari titik kantor';
    }

    final shiftText = selectedShift != null
        ? 'Shift: ${selectedShift!.name} [${_formatShortTime(selectedShift!.startTime)} - ${_formatShortTime(selectedShift!.endTime)}]'
        : 'Shift: OFFICE [08:00 - 16:00]';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Radius Status + Rute Button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      statusTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _launchRoute,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primary.withValues(alpha: 0.18)
                          : const Color(0xFFFFF1F5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Rute',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 2: Shift Information Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.6)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_filled_rounded,
                  size: 16,
                  color: context.textMutedColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    shiftText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Row 3: Action Button with Bouncing Spring Effect
          SizedBox(
            width: double.infinity,
            height: 52,
            child: BouncingButton(
              onPressed: isActionDisabled
                  ? null
                  : () {
                      AppHaptics.medium();
                      onAction();
                    },
              hapticType: BouncingHapticType.none,
              child: Container(
                decoration: BoxDecoration(
                  gradient: isActionDisabled
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFF2A88),
                            Color(0xFFE6007A),
                          ],
                        ),
                  color: isActionDisabled
                      ? (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB))
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  border: isActionDisabled
                      ? null
                      : Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_rounded,
                      size: 19,
                      color: isActionDisabled
                          ? (isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF))
                          : Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      actionBtnLabel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isActionDisabled
                          ? (isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF))
                          : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

