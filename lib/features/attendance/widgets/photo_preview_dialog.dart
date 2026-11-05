import 'package:flutter/material.dart';

import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/file_download_helper.dart';
import '../../../core/widgets/auto_oriented_image.dart';

class PhotoPreviewDialog extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String? subtitle;
  final String? customFileName;

  const PhotoPreviewDialog({
    super.key,
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.customFileName,
  });

  static Future<void> show(
    BuildContext context, {
    required String imageUrl,
    required String title,
    String? subtitle,
    String? customFileName,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => PhotoPreviewDialog(
        imageUrl: imageUrl,
        title: title,
        subtitle: subtitle,
        customFileName: customFileName,
      ),
    );
  }

  @override
  State<PhotoPreviewDialog> createState() => _PhotoPreviewDialogState();
}

class _PhotoPreviewDialogState extends State<PhotoPreviewDialog> {
  int _rotationTurns = 0;
  bool _isDownloading = false;
  bool _isSharing = false;

  Future<void> _shareMedia() async {
    if (_isSharing || _isDownloading) return;
    setState(() {
      _isSharing = true;
    });

    final result = await FileDownloadHelper.shareFile(
      urlOrPath: widget.imageUrl,
      customFileName: widget.customFileName,
      shareSubject: widget.title,
    );

    if (mounted) {
      setState(() {
        _isSharing = false;
      });

      if (!result.isSuccess && result.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFDC2626),
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.errorMessage!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _downloadMedia() async {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
    });

    final result = await FileDownloadHelper.downloadFile(
      urlOrPath: widget.imageUrl,
      customFileName: widget.customFileName,
    );

    if (mounted) {
      setState(() {
        _isDownloading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: result.isSuccess
              ? const Color(0xFF059669)
              : const Color(0xFFDC2626),
          content: Row(
            children: [
              Icon(
                result.isSuccess
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.isSuccess
                      ? 'Berhasil mengunduh ${result.fileName}'
                      : (result.errorMessage ?? 'Gagal mengunduh file.'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Share Media Button
                _isSharing
                    ? Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Tooltip(
                        message: 'Bagikan',
                        child: InkWell(
                          onTap: () {
                            AppHaptics.light();
                            _shareMedia();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.share_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                const SizedBox(width: 8),
                // Download Media Button
                _isDownloading
                    ? Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Tooltip(
                        message: 'Unduh Media',
                        child: InkWell(
                          onTap: () {
                            AppHaptics.light();
                            _downloadMedia();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.download_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                const SizedBox(width: 8),
                // Rotate Photo Button
                Tooltip(
                  message: 'Putar Gambar',
                  child: InkWell(
                    onTap: () {
                      AppHaptics.selection();
                      setState(() {
                        _rotationTurns = (_rotationTurns + 1) % 4;
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
                ),
                const SizedBox(width: 8),
                // Close Dialog Button
                Tooltip(
                  message: 'Tutup',
                  child: InkWell(
                    onTap: () {
                      AppHaptics.light();
                      Navigator.pop(context);
                    },
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
                  imageUrl: widget.imageUrl,
                  manualTurns: _rotationTurns,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
