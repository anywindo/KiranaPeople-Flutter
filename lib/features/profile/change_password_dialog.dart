import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  @override
  ConsumerState<ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _dialogError;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() async {
    setState(() {
      _dialogError = null;
    });

    if (_formKey.currentState?.validate() ?? false) {
      final success = await ref
          .read(authProvider.notifier)
          .changePassword(
            currentPassword: _currentController.text,
            newPassword: _newController.text,
            confirmPassword: _confirmController.text,
          );

      if (mounted) {
        if (success) {
          if (Navigator.of(context).canPop()) {
            Navigator.pop(context);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kata sandi berhasil diubah!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          final err =
              ref.read(authProvider).errorMessage ??
              'Gagal mengubah kata sandi.';
          setState(() {
            _dialogError = err;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return PopScope(
      canPop: !authState.isLoading,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Ubah Kata Sandi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_dialogError != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFEF4444),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _dialogError!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                TextFormField(
                  controller: _currentController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Kata Sandi Saat Ini',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Kata Sandi Baru',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Kolom ini wajib diisi';
                    if (v.length < 8) return 'Minimal 8 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Konfirmasi Kata Sandi Baru',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  validator: (v) {
                    if (v != _newController.text) {
                      return 'Konfirmasi kata sandi tidak cocok';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: authState.isLoading
                ? null
                : () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: authState.isLoading ? null : _submit,
            child: authState.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
