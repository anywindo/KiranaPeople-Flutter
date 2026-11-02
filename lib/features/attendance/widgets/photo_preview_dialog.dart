import 'package:flutter/material.dart';
import '../../../core/widgets/auto_oriented_image.dart';

class PhotoPreviewDialog extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String? subtitle;

  const PhotoPreviewDialog({
    super.key,
    required this.imageUrl,
    required this.title,
    this.subtitle,
  });

  static Future<void> show(
    BuildContext context, {
    required String imageUrl,
    required String title,
    String? subtitle,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => PhotoPreviewDialog(
        imageUrl: imageUrl,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  State<PhotoPreviewDialog> createState() => _PhotoPreviewDialogState();
}

class _PhotoPreviewDialogState extends State<PhotoPreviewDialog> {
  int _rotationTurns = 0;

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
                // Rotate Photo Button
                InkWell(
                  onTap: () {
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
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => Navigator.pop(context),
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

