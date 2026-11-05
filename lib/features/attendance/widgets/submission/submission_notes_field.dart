import 'package:flutter/material.dart';

class SubmissionNotesField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const SubmissionNotesField({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: const InputDecoration(
        labelText: 'Catatan (Opsional)',
        hintText: 'Misal: Bekerja dari kantor...',
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      maxLines: 2,
    );
  }
}
