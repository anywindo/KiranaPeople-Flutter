import 'package:flutter/material.dart';

class ConfirmationDialogs {
  ConfirmationDialogs._();

  static void showOfflineWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text(
              'Perangkat Offline',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Perangkat Anda saat ini tidak terhubung ke internet. Silakan aktifkan Wi-Fi atau data seluler Anda untuk mengirim presensi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  static void showGpsNotFoundDialog(
    BuildContext context,
    String? locationError,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Lokasi GPS Tidak Ditemukan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          locationError ?? 'Gagal mendapatkan lokasi GPS. Pastikan GPS dan izin lokasi telah diaktifkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  static void showOutsideRadiusDialog({
    required BuildContext context,
    required double distanceMeters,
    required double allowedRadiusMeters,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Di Luar Radius Kantor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Anda berada di luar radius kantor (${distanceMeters.round()}m dari batas yang diizinkan ${allowedRadiusMeters.round()}m). Anda harus berada di area kantor untuk melakukan presensi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }
}
