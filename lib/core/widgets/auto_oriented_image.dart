import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A smart image viewer that automatically inspects image dimensions and orients
/// sideways/landscape selfies to upright portrait, while supporting manual rotation.
class AutoOrientedImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int manualTurns;
  final void Function(int autoTurns)? onOrientationDetected;

  const AutoOrientedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.manualTurns = 0,
    this.onOrientationDetected,
  });

  /// Cache for detected orientation per URL to prevent flicker upon re-render.
  static final Map<String, int> _detectedTurnsCache = {};

  @override
  State<AutoOrientedImage> createState() => _AutoOrientedImageState();
}

class _AutoOrientedImageState extends State<AutoOrientedImage> {
  int _autoTurns = 0;
  ImageStream? _imageStream;
  ImageStreamListener? _streamListener;

  @override
  void initState() {
    super.initState();
    _autoTurns = AutoOrientedImage._detectedTurnsCache[widget.imageUrl] ?? 0;
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant AutoOrientedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _removeListener();
      _autoTurns = AutoOrientedImage._detectedTurnsCache[widget.imageUrl] ?? 0;
      _resolveImage();
    }
  }

  void _resolveImage() {
    if (widget.imageUrl.isEmpty) return;
    if (AutoOrientedImage._detectedTurnsCache.containsKey(widget.imageUrl)) {
      _autoTurns = AutoOrientedImage._detectedTurnsCache[widget.imageUrl]!;
      widget.onOrientationDetected?.call(_autoTurns);
      return;
    }

    try {
      final provider = CachedNetworkImageProvider(widget.imageUrl);
      final stream = provider.resolve(ImageConfiguration.empty);
      _imageStream = stream;
      _streamListener = ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          final w = info.image.width;
          final h = info.image.height;
          // If image width > height, it was captured sideways on an Android landscape sensor.
          // Rotating 270° clockwise (3 quarter turns) brings it upright portrait.
          final detectedTurns = (w > h) ? 3 : 0;
          AutoOrientedImage._detectedTurnsCache[widget.imageUrl] = detectedTurns;
          if (_autoTurns != detectedTurns && mounted) {
            setState(() {
              _autoTurns = detectedTurns;
            });
            widget.onOrientationDetected?.call(detectedTurns);
          }
        },
        onError: (e, stack) {},
      );
      stream.addListener(_streamListener!);
    } catch (_) {}
  }

  void _removeListener() {
    if (_imageStream != null && _streamListener != null) {
      _imageStream!.removeListener(_streamListener!);
    }
    _imageStream = null;
    _streamListener = null;
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalTurns = (_autoTurns + widget.manualTurns) % 4;

    Widget content = CachedNetworkImage(
      imageUrl: widget.imageUrl,
      fit: widget.fit,
      placeholder: (context, url) =>
          widget.placeholder ??
          const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      errorWidget: (context, url, error) =>
          widget.errorWidget ??
          const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.white54),
          ),
    );

    if (totalTurns != 0) {
      content = RotatedBox(
        quarterTurns: totalTurns,
        child: content,
      );
    }

    if (widget.width != null || widget.height != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: FittedBox(
          fit: widget.fit,
          clipBehavior: Clip.hardEdge,
          child: content,
        ),
      );
    }

    return content;
  }
}
