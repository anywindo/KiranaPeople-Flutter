import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/attendance_event_model.dart';
import '../../providers/history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  String _formatIndoDateString(String dateStr) {
    final dt = DateTime.tryParse(dateStr);
    if (dt != null) {
      const months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember'
      ];
      return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
    }
    return dateStr;
  }

  String _formatShortTime(String timeStr) {
    final dt = DateTime.tryParse(timeStr);
    if (dt != null) {
      final local = dt.isUtc ? dt.toLocal() : dt;
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
    if (timeStr.contains(' ')) {
      final parts = timeStr.split(' ');
      if (parts.length > 1 && parts[1].length >= 5) {
        return parts[1].substring(0, 5);
      }
    }
    if (timeStr.length >= 5) {
      return timeStr.substring(0, 5);
    }
    return timeStr;
  }

  IconData _getEventIcon(AttendanceEventType type) {
    switch (type) {
      case AttendanceEventType.startShift:
        return Icons.work_rounded;
      case AttendanceEventType.startBreak:
        return Icons.coffee_rounded;
      case AttendanceEventType.endBreak:
        return Icons.business_center_rounded;
      case AttendanceEventType.endShift:
        return Icons.home_rounded;
    }
  }

  void _showLocationModal(BuildContext context, AttendanceEvent event) {
    final lat = event.latitude ?? -6.9897;
    final lng = event.longitude ?? 109.8765;
    final latLng = LatLng(lat, lng);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Titik Presensi: ${event.eventType.label}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Koordinat: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 200,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: latLng,
                    initialZoom: 16.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'com.kiranadesainindonesia.kiranapeople',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: latLng,
                          width: 44,
                          height: 44,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_pin_circle_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Tutup',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FA),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Riwayat Presensi',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C1C1E),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () => ref.read(historyProvider.notifier).refresh(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F5),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFE4E6), width: 1),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(historyProvider.notifier).refresh(),
        child: historyState.records.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_toggle_off,
                      size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'Gagal memuat riwayat: $err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: AppColors.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () =>
                        ref.read(historyProvider.notifier).refresh(),
                    child: const Text('Muat Ulang'),
                  ),
                ],
              ),
            ),
          ),
          data: (records) {
            if (records.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 48, color: AppColors.textMuted),
                    SizedBox(height: 12),
                    Text(
                      'Belum ada riwayat presensi tercatat.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: records.length,
              separatorBuilder: (context, index) => const SizedBox(height: 18),
              itemBuilder: (context, index) {
                final item = records[index];
                final rawStatus = item.status ?? 'Tepat Waktu';
                String displayStatus = rawStatus;
                if (rawStatus.toUpperCase() == 'LATE') {
                  displayStatus = 'Terlambat';
                } else if (rawStatus.toUpperCase() == 'ON_TIME' ||
                    rawStatus.toUpperCase() == 'ONTIME' ||
                    rawStatus.toUpperCase() == 'HADIR') {
                  displayStatus = 'Tepat Waktu';
                }
                final isLate = rawStatus.toUpperCase() == 'LATE' ||
                    rawStatus.toLowerCase().contains('terlambat');
                final shiftName = item.shift?.name ?? 'OFFICE';
                final formattedDate = _formatIndoDateString(item.date);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header: Date + Badges (Matches Screenshot 3)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Row(
                          children: [
                            // Status Badge (Terlambat)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isLate
                                    ? const Color(0xFFFFF1F2)
                                    : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                displayStatus,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isLate
                                      ? const Color(0xFFE11D48)
                                      : const Color(0xFF15803D),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Shift Badge (OFFICE)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                shiftName,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Event Cards for that date (Matches Screenshot 3)
                    ...item.events.map((event) {
                      final timeStr = _formatShortTime(event.timestamp);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF2F2F7)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Circular Selfie Avatar
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFFE5E7EB), width: 1.5),
                              ),
                              child: ClipOval(
                                child: (event.fullSelfieUrl != null &&
                                        event.fullSelfieUrl!.isNotEmpty)
                                    ? CachedNetworkImage(
                                        imageUrl: event.fullSelfieUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: const Color(0xFFF3F4F6),
                                          child: const Center(
                                            child: SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                          color: const Color(0xFFFFF1F2),
                                          child: Icon(
                                            _getEventIcon(event.eventType),
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: const Color(0xFFFFF1F2),
                                        child: Icon(
                                          _getEventIcon(event.eventType),
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Event Title & Time
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.eventType.label,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time_rounded,
                                        size: 13,
                                        color: Color(0xFF8E8E93),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        timeStr,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF8E8E93),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Pink Map Button (Matches Screenshot 3)
                            InkWell(
                              onTap: () => _showLocationModal(context, event),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.map_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
