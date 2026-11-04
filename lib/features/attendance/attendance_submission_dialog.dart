import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import '../../core/security/device_security_service.dart';
import '../../core/services/face_detector_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/location_helper.dart';
import '../../data/models/attendance_event_model.dart';
import '../../providers/attendance_provider.dart';
import 'widgets/camera_device_integrity_dialog.dart';
import 'widgets/submission/submission_error_banner.dart';
import 'widgets/submission/submission_notes_field.dart';
import 'widgets/submission/submission_selfie_preview.dart';

class AttendanceSubmissionDialog extends ConsumerStatefulWidget {
  final AttendanceEventType eventType;

  const AttendanceSubmissionDialog({super.key, required this.eventType});

  static Future<bool?> show(
    BuildContext context,
    AttendanceEventType type,
  ) async {
    final isCompromised = await DeviceSecurityService().isDeviceCompromised();
    if (isCompromised && context.mounted) {
      await CameraDeviceIntegrityDialog.show(context);
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
  String? _dialogError;

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
        // Face detection verification
        final faceResult =
            await FaceDetectorService.instance.detectFaces(file);
        if (!faceResult.hasFace && mounted) {
          try {
            if (file.existsSync()) {
              file.deleteSync();
            }
          } catch (_) {}
          setState(() {
            _dialogError = faceResult.errorMessage ?? 'Wajah tidak terdeteksi.';
            _selfieImage = null;
          });
          return;
        }

        setState(() {
          _selfieImage = file;
          _dialogError = null;
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
            if (_dialogError != null)
              SubmissionErrorBanner(errorMessage: _dialogError!),
            const Text(
              'Silakan ambil foto selfie untuk verifikasi presensi Anda. GPS lokasi akan dicatat secara otomatis.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            SubmissionSelfiePreview(
              selfieImage: _selfieImage,
              onTap: _takePhoto,
              isSubmitting: state.isSubmitting,
            ),
            const SizedBox(height: 16),
            SubmissionNotesField(
              controller: _notesController,
              enabled: !state.isSubmitting,
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
