import 'package:flutter/material.dart';

class CameraDeviceIntegrityDialog extends StatelessWidget {
  const CameraDeviceIntegrityDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const CameraDeviceIntegrityDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Perangkat Tidak Didukung',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: const Text(
        'Aplikasi mendeteksi bahwa perangkat ini telah di-root atau di-jailbreak. Demi keamanan data dan keaslian presensi, presensi tidak dapat dilakukan pada perangkat yang dimodifikasi.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Mengerti'),
        ),
      ],
    );
  }
}
