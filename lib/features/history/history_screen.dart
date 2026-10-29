import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/attendance_event_model.dart';
import '../../data/models/work_location_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/history_provider.dart';
import '../../core/widgets/auto_oriented_image.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() async {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.maxScrollExtent > 0 &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 250) {
      final historyState = ref.read(historyProvider);
      if (historyState.hasMore && !_isLoadingMore) {
        setState(() {
          _isLoadingMore = true;
        });
        await ref
            .read(historyProvider.notifier)
            .loadHistory(page: historyState.currentPage + 1);
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      }
    }
  }

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
        'Desember',
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

  void _showPhotoPreviewDialog(
    BuildContext context, {
    required String imageUrl,
    required String title,
    String? subtitle,
  }) {
    int rotationTurns = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Rotate Photo Button
                    InkWell(
                      onTap: () {
                        setDialogState(() {
                          rotationTurns = (rotationTurns + 1) % 4;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.rotate_right_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                child: Container(
                  color: Colors.black,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.65,
                    minHeight: 250,
                    minWidth: double.infinity,
                  ),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: AutoOrientedImage(
                      imageUrl: imageUrl,
                      manualTurns: rotationTurns,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLocationModal(
    BuildContext context,
    AttendanceEvent event, [
    WorkLocation? workLocation,
  ]) {
    final lat = event.latitude ?? -7.025648;
    final lng = event.longitude ?? 109.957296;
    final userLatLng = LatLng(lat, lng);

    final officeLatLng = workLocation != null
        ? LatLng(workLocation.latitude, workLocation.longitude)
        : const LatLng(-7.025801, 109.956894);

    final officeName =
        (workLocation?.name != null && workLocation!.name.isNotEmpty)
        ? workLocation.name
        : 'Kantor Utama (Tersono, Batang)';

    final radius = workLocation?.radius ?? 50.0;

    final distance = Geolocator.distanceBetween(
      userLatLng.latitude,
      userLatLng.longitude,
      officeLatLng.latitude,
      officeLatLng.longitude,
    );
    final isInside = distance <= radius;
    final hasPhoto =
        event.fullSelfieUrl != null && event.fullSelfieUrl!.isNotEmpty;
    int selectedTab = 0; // 0 = Map, 1 = Foto

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (hasPhoto)
                    GestureDetector(
                      onTap: () => _showPhotoPreviewDialog(
                        context,
                        imageUrl: event.fullSelfieUrl!,
                        title: 'Foto Presensi: ${event.eventType.label}',
                        subtitle:
                            'Koordinat: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                      ),
                      child: Stack(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: AutoOrientedImage(
                                imageUrl: event.fullSelfieUrl!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorWidget: const Icon(
                                  Icons.person_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.search_rounded,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Koordinat: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (hasPhoto) ...[
                const SizedBox(height: 14),
                Container(
                  height: 38,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: context.surfaceSecondaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => selectedTab = 0),
                          borderRadius: BorderRadius.circular(9),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selectedTab == 0
                                  ? context.surfaceColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: selectedTab == 0
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.06,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.map_rounded,
                                  size: 15,
                                  color: selectedTab == 0
                                      ? AppColors.primary
                                      : context.textSecondaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Peta Lokasi (2 Pin)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: selectedTab == 0
                                        ? AppColors.primary
                                        : context.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => selectedTab = 1),
                          borderRadius: BorderRadius.circular(9),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selectedTab == 1
                                  ? context.surfaceColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: selectedTab == 1
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.06,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt_rounded,
                                  size: 15,
                                  color: selectedTab == 1
                                      ? AppColors.primary
                                      : context.textSecondaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Foto Selfie',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: selectedTab == 1
                                        ? AppColors.primary
                                        : context.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              if (selectedTab == 1 && hasPhoto)
                GestureDetector(
                  onTap: () => _showPhotoPreviewDialog(
                    context,
                    imageUrl: event.fullSelfieUrl!,
                    title: 'Foto Presensi: ${event.eventType.label}',
                    subtitle:
                        'Koordinat: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 220,
                          width: double.infinity,
                          color: const Color(0xFF0F172A),
                          child: AutoOrientedImage(
                            imageUrl: event.fullSelfieUrl!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fullscreen_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Perbesar Foto',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 220,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCameraFit: CameraFit.coordinates(
                          coordinates: [userLatLng, officeLatLng],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 48,
                          ),
                          maxZoom: 17.0,
                        ),
                        initialCenter: userLatLng,
                        initialZoom: 16.5,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.kiranadesainindonesia.kiranapeople',
                        ),
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: officeLatLng,
                              radius: radius,
                              useRadiusInMeter: true,
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderColor: AppColors.primary,
                              borderStrokeWidth: 1.5,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            // 1. Office Pin (Kantor)
                            Marker(
                              point: officeLatLng,
                              width: 140,
                              height: 64,
                              alignment: Alignment.topCenter,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.apartment_rounded,
                                          color: Colors.white,
                                          size: 10,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            officeName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.apartment_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 2. User Pin (Posisi User)
                            Marker(
                              point: userLatLng,
                              width: 120,
                              height: 64,
                              alignment: Alignment.topCenter,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF007AFF),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.person_pin_circle_rounded,
                                          color: Colors.white,
                                          size: 11,
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          'Posisi User',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF007AFF),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.person_pin_circle_rounded,
                              size: 16,
                              color: Color(0xFF007AFF),
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Posisi User',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0369A1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECDD3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.apartment_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                officeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
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
                ),
              ],
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
      ),
    );
  }

  String _formatDateRangeLabel(DateTimeRange range) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final startDay = range.start.day;
    final startMonth = months[range.start.month - 1];
    final endDay = range.end.day;
    final endMonth = months[range.end.month - 1];

    if (range.start.year == range.end.year &&
        range.start.month == range.end.month &&
        range.start.day == range.end.day) {
      return '$startDay $startMonth ${range.start.year}';
    }
    if (range.start.year == range.end.year) {
      return '$startDay $startMonth - $endDay $endMonth';
    }
    return '$startDay $startMonth ${range.start.year} - $endDay $endMonth ${range.end.year}';
  }

  Future<void> _pickCustomDateRange(
    BuildContext context,
    HistoryState historyState,
  ) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      initialDateRange: historyState.filter.dateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      cancelText: 'Batal',
      confirmText: 'Pilih',
      saveText: 'Simpan',
      helpText: 'Pilih Rentang Tanggal',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: context.surfaceColor,
              onSurface: context.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final label = _formatDateRangeLabel(picked);
      ref.read(historyProvider.notifier).setDateRangeFilter(picked, label);
    }
  }

  void _showDateFilterSheet(BuildContext context, HistoryState historyState) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Periode Tanggal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
                if (historyState.filter.dateRange != null)
                  TextButton(
                    onPressed: () {
                      ref
                          .read(historyProvider.notifier)
                          .setDateRangeFilter(null);
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Hapus Filter',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSheetOption(
              context,
              title: 'Semua Waktu',
              subtitle: 'Tampilkan seluruh riwayat presensi',
              isSelected: historyState.filter.dateRange == null,
              onTap: () {
                ref.read(historyProvider.notifier).setDateRangeFilter(null);
                Navigator.pop(ctx);
              },
            ),
            _buildSheetOption(
              context,
              title: 'Hari Ini',
              subtitle:
                  '${today.day} ${_formatIndoDateString(today.toIso8601String()).split(', ').last}',
              isSelected: historyState.filter.dateRangeLabel == 'Hari Ini',
              onTap: () {
                final range = DateTimeRange(start: today, end: today);
                ref
                    .read(historyProvider.notifier)
                    .setDateRangeFilter(range, 'Hari Ini');
                Navigator.pop(ctx);
              },
            ),
            _buildSheetOption(
              context,
              title: '7 Hari Terakhir',
              subtitle: 'Presensi satu minggu ke belakang',
              isSelected:
                  historyState.filter.dateRangeLabel == '7 Hari Terakhir',
              onTap: () {
                final range = DateTimeRange(
                  start: today.subtract(const Duration(days: 6)),
                  end: today,
                );
                ref
                    .read(historyProvider.notifier)
                    .setDateRangeFilter(range, '7 Hari Terakhir');
                Navigator.pop(ctx);
              },
            ),
            _buildSheetOption(
              context,
              title: 'Bulan Ini',
              subtitle:
                  '1 - ${today.day} ${_formatIndoDateString(today.toIso8601String()).split(', ').last}',
              isSelected: historyState.filter.dateRangeLabel == 'Bulan Ini',
              onTap: () {
                final startOfMonth = DateTime(today.year, today.month, 1);
                final range = DateTimeRange(start: startOfMonth, end: today);
                ref
                    .read(historyProvider.notifier)
                    .setDateRangeFilter(range, 'Bulan Ini');
                Navigator.pop(ctx);
              },
            ),
            _buildSheetOption(
              context,
              title: 'Pilih Rentang Tanggal Manual...',
              subtitle: 'Tentukan tanggal mulai dan selesai sendiri',
              isSelected: historyState.filter.dateRange != null &&
                  historyState.filter.dateRangeLabel != 'Hari Ini' &&
                  historyState.filter.dateRangeLabel != '7 Hari Terakhir' &&
                  historyState.filter.dateRangeLabel != 'Bulan Ini',
              icon: Icons.date_range_rounded,
              onTap: () {
                Navigator.pop(ctx);
                _pickCustomDateRange(context, historyState);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showShiftFilterSheet(
    BuildContext context,
    List<String> shifts,
    HistoryState historyState,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Filter Shift Kerja',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            ...shifts.map((s) {
              final isSelected =
                  (historyState.filter.shift ?? 'Semua Shift') == s;
              return _buildSheetOption(
                context,
                title: s,
                isSelected: isSelected,
                onTap: () {
                  ref
                      .read(historyProvider.notifier)
                      .setShiftFilter(s == 'Semua Shift' ? null : s);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetOption(
    BuildContext context, {
    required String title,
    String? subtitle,
    required bool isSelected,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 20,
                color:
                    isSelected ? AppColors.primary : context.textSecondaryColor,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : context.textPrimaryColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textMutedColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showFullFilterSheet(BuildContext context) {
    final historyState = ref.read(historyProvider);
    var tempStatus = historyState.filter.status;
    var tempRange = historyState.filter.dateRange;
    var tempRangeLabel = historyState.filter.dateRangeLabel;
    var tempShift = historyState.filter.shift ?? 'Semua Shift';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Riwayat Presensi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: context.textSecondaryColor,
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // 1. Status Filter
                  Text(
                    'Status Kehadiran',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChipChoice(
                        context,
                        label: 'Semua Status',
                        isSelected:
                            tempStatus == AttendanceHistoryStatusFilter.all,
                        onTap: () => setSheetState(
                          () =>
                              tempStatus = AttendanceHistoryStatusFilter.all,
                        ),
                      ),
                      _buildChipChoice(
                        context,
                        label: 'Tepat Waktu',
                        isSelected:
                            tempStatus == AttendanceHistoryStatusFilter.onTime,
                        selectedColor: const Color(0xFF15803D),
                        selectedBg: const Color(0xFFDCFCE7),
                        onTap: () => setSheetState(
                          () =>
                              tempStatus = AttendanceHistoryStatusFilter.onTime,
                        ),
                      ),
                      _buildChipChoice(
                        context,
                        label: 'Terlambat',
                        isSelected:
                            tempStatus == AttendanceHistoryStatusFilter.late,
                        selectedColor: const Color(0xFFE11D48),
                        selectedBg: const Color(0xFFFFF1F2),
                        onTap: () => setSheetState(
                          () =>
                              tempStatus = AttendanceHistoryStatusFilter.late,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. Periode / Tanggal
                  Text(
                    'Periode Tanggal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChipChoice(
                        context,
                        label: 'Semua',
                        isSelected: tempRange == null,
                        onTap: () => setSheetState(() {
                          tempRange = null;
                          tempRangeLabel = null;
                        }),
                      ),
                      _buildChipChoice(
                        context,
                        label: 'Hari Ini',
                        isSelected: tempRangeLabel == 'Hari Ini',
                        onTap: () {
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          setSheetState(() {
                            tempRange =
                                DateTimeRange(start: today, end: today);
                            tempRangeLabel = 'Hari Ini';
                          });
                        },
                      ),
                      _buildChipChoice(
                        context,
                        label: '7 Hari Terakhir',
                        isSelected: tempRangeLabel == '7 Hari Terakhir',
                        onTap: () {
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          setSheetState(() {
                            tempRange = DateTimeRange(
                              start: today.subtract(const Duration(days: 6)),
                              end: today,
                            );
                            tempRangeLabel = '7 Hari Terakhir';
                          });
                        },
                      ),
                      _buildChipChoice(
                        context,
                        label: 'Bulan Ini',
                        isSelected: tempRangeLabel == 'Bulan Ini',
                        onTap: () {
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          setSheetState(() {
                            tempRange = DateTimeRange(
                              start: DateTime(today.year, today.month, 1),
                              end: today,
                            );
                            tempRangeLabel = 'Bulan Ini';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: tempRange != null &&
                                tempRangeLabel != 'Hari Ini' &&
                                tempRangeLabel != '7 Hari Terakhir' &&
                                tempRangeLabel != 'Bulan Ini'
                            ? AppColors.primary
                            : context.borderColor,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(now.year - 3),
                        lastDate: DateTime(now.year + 1),
                        initialDateRange: tempRange ??
                            DateTimeRange(
                              start: now.subtract(const Duration(days: 30)),
                              end: now,
                            ),
                        cancelText: 'Batal',
                        confirmText: 'Pilih',
                        saveText: 'Simpan',
                        helpText: 'Pilih Rentang Tanggal',
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: AppColors.primary,
                                onPrimary: Colors.white,
                                surface: context.surfaceColor,
                                onSurface: context.textPrimaryColor,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setSheetState(() {
                          tempRange = picked;
                          tempRangeLabel = _formatDateRangeLabel(picked);
                        });
                      }
                    },
                    icon: const Icon(Icons.date_range_rounded, size: 18),
                    label: Text(
                      tempRange != null &&
                              tempRangeLabel != 'Hari Ini' &&
                              tempRangeLabel != '7 Hari Terakhir' &&
                              tempRangeLabel != 'Bulan Ini'
                          ? 'Rentang: $tempRangeLabel'
                          : 'Pilih Rentang Tanggal Manual...',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Shift Filter
                  if (historyState.availableShifts.length > 1) ...[
                    Text(
                      'Shift Kerja',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: context.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: historyState.availableShifts.map((s) {
                        final isSelected = tempShift == s;
                        return _buildChipChoice(
                          context,
                          label: s,
                          isSelected: isSelected,
                          onTap: () => setSheetState(() => tempShift = s),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.textSecondaryColor,
                            side: BorderSide(color: context.borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            ref.read(historyProvider.notifier).resetFilter();
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            'Reset',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            final notifier =
                                ref.read(historyProvider.notifier);
                            notifier.setStatusFilter(tempStatus);
                            notifier.setDateRangeFilter(
                              tempRange,
                              tempRangeLabel,
                            );
                            notifier.setShiftFilter(
                              tempShift == 'Semua Shift' ? null : tempShift,
                            );
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            'Terapkan Filter',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChipChoice(
    BuildContext context, {
    required String label,
    required bool isSelected,
    Color? selectedColor,
    Color? selectedBg,
    required VoidCallback onTap,
  }) {
    final activeBg =
        selectedBg ?? AppColors.primary.withValues(alpha: 0.12);
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

  Widget _buildFilterBar(BuildContext context, HistoryState historyState) {
    final filter = historyState.filter;
    final notifier = ref.read(historyProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: context.scaffoldBg,
        border: Border(
          bottom: BorderSide(
            color: context.borderColor.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Status: Semua
            _buildQuickFilterPill(
              context,
              label: 'Semua',
              isSelected: filter.status == AttendanceHistoryStatusFilter.all,
              onTap: () =>
                  notifier.setStatusFilter(AttendanceHistoryStatusFilter.all),
            ),
            const SizedBox(width: 8),

            // Status: Tepat Waktu
            _buildQuickFilterPill(
              context,
              label: 'Tepat Waktu',
              icon: Icons.check_circle_rounded,
              isSelected: filter.status == AttendanceHistoryStatusFilter.onTime,
              activeColor: const Color(0xFF15803D),
              activeBg: const Color(0xFFDCFCE7),
              onTap: () => notifier.setStatusFilter(
                filter.status == AttendanceHistoryStatusFilter.onTime
                    ? AttendanceHistoryStatusFilter.all
                    : AttendanceHistoryStatusFilter.onTime,
              ),
            ),
            const SizedBox(width: 8),

            // Status: Terlambat
            _buildQuickFilterPill(
              context,
              label: 'Terlambat',
              icon: Icons.alarm_rounded,
              isSelected: filter.status == AttendanceHistoryStatusFilter.late,
              activeColor: const Color(0xFFE11D48),
              activeBg: const Color(0xFFFFF1F2),
              onTap: () => notifier.setStatusFilter(
                filter.status == AttendanceHistoryStatusFilter.late
                    ? AttendanceHistoryStatusFilter.all
                    : AttendanceHistoryStatusFilter.late,
              ),
            ),
            const SizedBox(width: 8),

            // Date Range Chip
            _buildQuickFilterPill(
              context,
              label: filter.dateRange != null
                  ? (filter.dateRangeLabel ?? 'Rentang Tanggal')
                  : 'Tanggal',
              icon: Icons.calendar_month_rounded,
              trailingIcon: filter.dateRange != null
                  ? Icons.close_rounded
                  : Icons.keyboard_arrow_down_rounded,
              isSelected: filter.dateRange != null,
              onTap: () => _showDateFilterSheet(context, historyState),
              onTrailingTap: filter.dateRange != null
                  ? () => notifier.setDateRangeFilter(null)
                  : null,
            ),

            // Shift Chip (if shifts available)
            if (historyState.availableShifts.length > 2) ...[
              const SizedBox(width: 8),
              _buildQuickFilterPill(
                context,
                label: filter.shift != null && filter.shift != 'Semua Shift'
                    ? filter.shift!
                    : 'Shift',
                icon: Icons.access_time_rounded,
                trailingIcon:
                    filter.shift != null && filter.shift != 'Semua Shift'
                        ? Icons.close_rounded
                        : Icons.keyboard_arrow_down_rounded,
                isSelected:
                    filter.shift != null && filter.shift != 'Semua Shift',
                onTap: () => _showShiftFilterSheet(
                  context,
                  historyState.availableShifts,
                  historyState,
                ),
                onTrailingTap:
                    filter.shift != null && filter.shift != 'Semua Shift'
                        ? () => notifier.setShiftFilter(null)
                        : null,
              ),
            ],

            // Reset chip (when filter active)
            if (filter.isActive) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () => notifier.resetFilter(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: context.surfaceSecondaryColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 14,
                        color: context.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilterPill(
    BuildContext context, {
    required String label,
    IconData? icon,
    IconData? trailingIcon,
    required bool isSelected,
    Color? activeColor,
    Color? activeBg,
    required VoidCallback onTap,
    VoidCallback? onTrailingTap,
  }) {
    final textColor = isSelected
        ? (activeColor ?? Colors.white)
        : context.textSecondaryColor;
    final bgColor = isSelected
        ? (activeBg ?? AppColors.primary)
        : context.surfaceColor;
    final borderColor = isSelected
        ? (activeColor ?? AppColors.primary)
        : context.borderColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: textColor),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: textColor,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onTrailingTap ?? onTap,
                child: Icon(trailingIcon, size: 14, color: textColor),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilterState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.filter_list_off_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak Ada Riwayat Sesuai Filter',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba ubah status, shift, atau rentang tanggal yang dipilih.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: context.textMutedColor,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                ref.read(historyProvider.notifier).resetFilter();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Reset Semua Filter',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyProvider);
    final user = ref.watch(authProvider).user;
    final workLocation = user?.location;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Riwayat Presensi',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: context.textPrimaryColor,
          ),
        ),
        actions: [
          // Filter Button with Badge
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                InkWell(
                  onTap: () => _showFullFilterSheet(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: historyState.filter.isActive
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : context.surfaceSecondaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: historyState.filter.isActive
                            ? AppColors.primary
                            : context.borderColor,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: historyState.filter.isActive
                          ? AppColors.primary
                          : context.textSecondaryColor,
                      size: 18,
                    ),
                  ),
                ),
                if (historyState.filter.isActive)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          '${historyState.filter.activeFilterCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Refresh Button
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () => ref.read(historyProvider.notifier).refresh(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.surfaceSecondaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.borderColor, width: 1),
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
      body: Column(
        children: [
          // Filter Chips Bar
          _buildFilterBar(context, historyState),

          // Background Syncing Indicator
          AnimatedOpacity(
            opacity: historyState.isBackgroundSyncing ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primary.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),

          // History List
          Expanded(
            child: RefreshIndicator(
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
                        const Icon(
                          Icons.history_toggle_off,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Gagal memuat riwayat: $err',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.error,
                          ),
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
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
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

                  final filteredList = historyState.filteredRecords;
                  if (filteredList.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 40),
                        _buildEmptyFilterState(context),
                      ],
                    );
                  }

                  final showLoadingMore =
                      historyState.hasMore && !historyState.filter.isActive;
                  return ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: filteredList.length + (showLoadingMore ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 18),
                    itemBuilder: (context, index) {
                      if (index == filteredList.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        );
                      }
                      final item = filteredList[index];
                      final rawStatus = item.status ?? 'Tepat Waktu';
                      String displayStatus = rawStatus;
                      if (rawStatus.toUpperCase() == 'LATE') {
                        displayStatus = 'Terlambat';
                      } else if (rawStatus.toUpperCase() == 'ON_TIME' ||
                          rawStatus.toUpperCase() == 'ONTIME' ||
                          rawStatus.toUpperCase() == 'HADIR') {
                        displayStatus = 'Tepat Waktu';
                      }
                      final isLate =
                          rawStatus.toUpperCase() == 'LATE' ||
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
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                              Row(
                                children: [
                                  // Status Badge (Terlambat)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
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
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.surfaceSecondaryColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      shiftName,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: context.textSecondaryColor,
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
                              decoration: BoxDecoration(
                                color: context.surfaceColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: context.borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  onTap: () => _showLocationModal(
                                    context,
                                    event,
                                    workLocation,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        // Circular Selfie Avatar or Event Icon
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: context.borderColor,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: ClipOval(
                                            child:
                                                (event.fullSelfieUrl != null &&
                                                    event
                                                        .fullSelfieUrl!
                                                        .isNotEmpty)
                                                ? AutoOrientedImage(
                                                    imageUrl:
                                                        event.fullSelfieUrl!,
                                                    width: 44,
                                                    height: 44,
                                                    fit: BoxFit.cover,
                                                    errorWidget: Container(
                                                      color: AppColors.primary
                                                          .withValues(
                                                            alpha: 0.12,
                                                          ),
                                                      child: Icon(
                                                        _getEventIcon(
                                                          event.eventType,
                                                        ),
                                                        color:
                                                            AppColors.primary,
                                                        size: 20,
                                                      ),
                                                    ),
                                                  )
                                                : Container(
                                                    color: AppColors.primary
                                                        .withValues(
                                                          alpha: 0.12,
                                                        ),
                                                    child: Icon(
                                                      _getEventIcon(
                                                        event.eventType,
                                                      ),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                event.eventType.label,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      context.textPrimaryColor,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time_rounded,
                                                    size: 13,
                                                    color: context
                                                        .textSecondaryColor,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    timeStr,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: context
                                                          .textSecondaryColor,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  if (event.latitude != null &&
                                                      event.longitude !=
                                                          null) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      width: 3,
                                                      height: 3,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            context.borderColor,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Icon(
                                                      Icons.location_on_rounded,
                                                      size: 12,
                                                      color: Color(0xFF94A3B8),
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      'Lokasi GPS',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: context
                                                            .textMutedColor,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Subtle Chevron Icon
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color:
                                                context.surfaceSecondaryColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: context.borderColor,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.chevron_right_rounded,
                                            color: context.textMutedColor,
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
          ),
        ],
      ),
    );
  }
}
