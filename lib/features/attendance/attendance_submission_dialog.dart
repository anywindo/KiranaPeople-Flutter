import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import '../../core/security/device_security_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/location_helper.dart';
import '../../data/models/attendance_event_model.dart';
import '../../providers/attendance_provider.dart';

class AttendanceSubmissionDialog extends ConsumerStatefulWidget {
  final AttendanceEventType eventType;

  const AttendanceSubmissionDialog({super.key, required this.eventType});

  static Future<bool?> show(BuildContext context, AttendanceEventType type) async {
    final isCompromised = await DeviceSecurityService().isDeviceCompromised();
    if (isCompromised && context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Perangkat Tidak Didukung', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'Aplikasi mendeteksi bahwa perangkat ini telah di-root atau di-jailbreak. Demi keamanan data dan keaslian presensi, presensi tidak dapat dilakukan pada perangkat yang dimodifikasi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      return false;
    }

    if (!context.mounted) return false;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AttendanceSubmissionDialog(eventType: type),
    );
  }

  @override
  ConsumerState<AttendanceSubmissionDialog> createState() =>
      _AttendanceSubmissionDialogState();
}

class _AttendanceSubmissionDialogState
    extends ConsumerState<AttendanceSubmissionDialog> {
  File? _selfieImage;
  final _picker = ImagePicker();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    if (_selfieImage != null) {
      try {
        if (_selfieImage!.existsSync()) {
          _selfieImage!.deleteSync();
        }
      } catch (_) {}
    }
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 960,
        maxHeight: 960,
        imageQuality: 75,
      );
      if (picked != null) {
        // Clean up previously captured selfie before replacing
        if (_selfieImage != null) {
          try {
            if (_selfieImage!.existsSync()) {
              _selfieImage!.deleteSync();
            }
          } catch (_) {}
        }
        final file = File(picked.path);
        try {
          final bytes = await file.readAsBytes();
          final decoded = img.decodeImage(bytes);
          if (decoded != null) {
            img.Image oriented = img.bakeOrientation(decoded);
            oriented = img.flipHorizontal(oriented);
            await file.writeAsBytes(img.encodeJpg(oriented, quality: 75));
          }
        } catch (_) {}
        setState(() {
          _selfieImage = file;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dialogError = 'Gagal membuka kamera: $e';
        });
      }
    }
  }

  String? _dialogError;

  void _submit() async {
    setState(() {
      _dialogError = null;
    });

    double lat = 0.0;
    double lng = 0.0;
    double? acc;
    double? alt;
    DateTime? timestamp;
    bool isMock = false;
    try {
      final pos = await LocationHelper.determinePosition();
      lat = pos.latitude;
      lng = pos.longitude;
      acc = pos.accuracy;
      alt = pos.altitude;
      timestamp = pos.timestamp;
      isMock = pos.isMocked;
    } catch (e) {
      if (mounted) {
        setState(() {
          _dialogError = e.toString().replaceFirst('Exception: ', '');
        });
      }
      return;
    }

    final success = await ref
        .read(todayAttendanceProvider.notifier)
        .submitEvent(
          eventType: widget.eventType,
          latitude: lat,
          longitude: lng,
          accuracy: acc,
          altitude: alt,
          deviceTimestamp: timestamp,
          isMocked: isMock,
          photoFile: _selfieImage,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (mounted) {
      if (success) {
        // Purge temporary selfie image from local storage
        try {
          if (_selfieImage != null && _selfieImage!.existsSync()) {
            _selfieImage!.deleteSync();
          }
        } catch (_) {}
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.eventType.label} berhasil dicatat!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        final err =
            ref.read(todayAttendanceProvider).submitError ??
            'Gagal mencatat presensi.';
        setState(() {
          _dialogError = err;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todayAttendanceProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.touch_app, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Konfirmasi ${widget.eventType.label}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_dialogError != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                margin: const EdgeInsets.only(bottom: 12),
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
            const Text(
              'Silakan ambil foto selfie untuk verifikasi presensi Anda. GPS lokasi akan dicatat secara otomatis.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Selfie preview or camera trigger
            GestureDetector(
              onTap: state.isSubmitting ? null : _takePhoto,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selfieImage != null
                        ? AppColors.primary
                        : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: _selfieImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_selfieImage!, fit: BoxFit.cover),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Ubah Foto',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 32,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Ketuk untuk Ambil Foto Selfie',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Wajib verifikasi wajah',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Optional note input
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan (Opsional)',
                hintText: 'Misal: Bekerja dari kantor...',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: state.isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          child: state.isSubmitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Kirim Presensi'),
        ),
      ],
    );
  }
}
