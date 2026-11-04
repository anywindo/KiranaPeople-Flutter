import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../providers/auth_provider.dart';
import '../profile_actions.dart';

class EditPhoneSheet extends StatefulWidget {
  final String? initialPhone;
  final WidgetRef ref;

  const EditPhoneSheet({
    super.key,
    this.initialPhone,
    required this.ref,
  });

  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    String? currentPhone,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => EditPhoneSheet(
        initialPhone: currentPhone,
        ref: ref,
      ),
    );
  }

  @override
  State<EditPhoneSheet> createState() => _EditPhoneSheetState();
}

class _EditPhoneSheetState extends State<EditPhoneSheet> {
  late final TextEditingController _phoneController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.pop(context);
    final success = await widget.ref
        .read(authProvider.notifier)
        .updateProfile(phone: _phoneController.text.trim());

    if (mounted) {
      if (success) {
        ProfileActions.showCustomToast(
          context,
          'Nomor telepon berhasil diperbarui!',
        );
      } else {
        final err =
            widget.ref.read(authProvider).errorMessage ??
            'Gagal memperbarui nomor telepon.';
        ProfileActions.showCustomToast(context, err, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
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
              'Ubah Nomor Telepon',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Masukkan nomor telepon aktif untuk verifikasi dan kontak.',
              style: TextStyle(
                fontSize: 13,
                color: context.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              autofocus: true,
              style: TextStyle(color: context.textPrimaryColor),
              decoration: InputDecoration(
                hintText: '08xxxxxxxxxx',
                hintStyle: TextStyle(color: context.textMutedColor),
                prefixIcon: const Icon(
                  Icons.phone_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                filled: true,
                fillColor: context.surfaceSecondaryColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nomor telepon tidak boleh kosong';
                }
                final digits = val.replaceAll(RegExp(r'\D'), '');
                if (digits.length < 9 || digits.length > 15) {
                  return 'Nomor harus terdiri dari 9 hingga 15 digit angka';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
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
                  elevation: 0,
                ),
                onPressed: _submit,
                child: const Text(
                  'Simpan Nomor',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

