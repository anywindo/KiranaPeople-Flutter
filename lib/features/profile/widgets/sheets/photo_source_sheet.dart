import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../providers/auth_provider.dart';
import '../dialogs/photo_confirm_dialog.dart';
import '../profile_actions.dart';

class PhotoSourceSheet extends StatelessWidget {
  const PhotoSourceSheet({super.key});

  static void show(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Foto Profil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pilih foto baru dari galeri atau ambil langsung dengan kamera.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? const Color(0xFF332042)
                        : const Color(0xFFFFF1F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Buka Galeri Foto',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: context.textPrimaryColor,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: context.borderColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(context, ref, ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? const Color(0xFF1E3A5F)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                ),
                title: Text(
                  'Ambil dengan Kamera',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: context.textPrimaryColor,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: context.borderColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(context, ref, ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _pickAndUploadImage(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (picked == null) return;

      final file = File(picked.path);
      if (!context.mounted) return;

      final confirm = await PhotoConfirmDialog.show(context, file);

      if (confirm != true) {
        if (source == ImageSource.camera) {
          try {
            if (file.existsSync()) file.deleteSync();
          } catch (_) {}
        }
        return;
      }

      try {
        final success = await ref
            .read(authProvider.notifier)
            .updateProfile(avatarFile: file);
        if (context.mounted) {
          if (success) {
            ProfileActions.showCustomToast(
              context,
              'Foto profil berhasil diperbarui!',
            );
          } else {
            final err =
                ref.read(authProvider).errorMessage ??
                'Gagal memperbarui foto profil.';
            ProfileActions.showCustomToast(context, err, isError: true);
          }
        }
      } finally {
        if (source == ImageSource.camera) {
          try {
            if (file.existsSync()) file.deleteSync();
          } catch (_) {}
        }
      }
    } catch (e) {
      if (context.mounted) {
        ProfileActions.showCustomToast(
          context,
          'Gagal memilih foto: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

