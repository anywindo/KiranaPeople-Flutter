import 'package:flutter/material.dart';

class AttendanceErrorDialog extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onDismiss;

  const AttendanceErrorDialog({
    super.key,
    required this.errorMessage,
    required this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required String errorMessage,
    required VoidCallback onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AttendanceErrorDialog(
        errorMessage: errorMessage,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Presensi Belum Tersimpan',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Text(errorMessage),
      actions: [
        TextButton(
          onPressed: () {
            onDismiss();
            Navigator.pop(context);
          },
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}

