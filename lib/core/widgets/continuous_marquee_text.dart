import 'package:flutter/material.dart';

/// A widget that displays text and continuously scrolls it horizontally (marquee)
/// only if the text overflows the available maximum width.
/// If the text fits, it renders as a normal static Text widget.
class ContinuousMarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double velocity;
  final double blankSpace;
  final double fadeWidth;

  const ContinuousMarqueeText({
    super.key,
    required this.text,
    this.style,
    this.velocity = 32.0, // pixels per second
    this.blankSpace = 32.0, // space between looping repetitions
    this.fadeWidth = 10.0, // edge fade-out width in pixels
  });

  @override
  State<ContinuousMarqueeText> createState() => _ContinuousMarqueeTextState();
}

class _ContinuousMarqueeTextState extends State<ContinuousMarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _textWidth = 0.0;
  double _lastAvailableWidth = -1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant ContinuousMarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.style != widget.style ||
        oldWidget.velocity != widget.velocity ||
        oldWidget.blankSpace != widget.blankSpace) {
      _lastAvailableWidth = -1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _calculateAndAnimate(double maxWidth, TextStyle effectiveStyle, TextScaler textScaler) {
    if (maxWidth.isInfinite || maxWidth <= 0) return;

    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: effectiveStyle),
      textDirection: Directionality.of(context),
      textScaler: textScaler,
      maxLines: 1,
    )..layout();

    _textWidth = textPainter.width;
    _lastAvailableWidth = maxWidth;

    final isOverflowing = _textWidth > maxWidth;

    if (isOverflowing) {
      final totalScrollDistance = _textWidth + widget.blankSpace;
      final durationMs = ((totalScrollDistance / widget.velocity) * 1000).round();
      final newDuration = Duration(milliseconds: durationMs.clamp(1000, 60000));

      if (_controller.duration != newDuration) {
        _controller.duration = newDuration;
      }
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      if (_controller.isAnimating) {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final effectiveStyle = defaultStyle.merge(widget.style);
    final textScaler = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        if (maxWidth.isFinite && maxWidth > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_lastAvailableWidth != maxWidth) {
              _calculateAndAnimate(maxWidth, effectiveStyle, textScaler);
            }
          });
        }

        // Measure immediately for rendering decisions
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: effectiveStyle),
          textDirection: Directionality.of(context),
          textScaler: textScaler,
          maxLines: 1,
        )..layout();

        final textWidth = textPainter.width;
        final isOverflow = maxWidth.isFinite && textWidth > maxWidth;

        if (!isOverflow) {
          return Text(
            widget.text,
            style: effectiveStyle,
            maxLines: 1,
            overflow: TextOverflow.clip,
          );
        }

        final scrollDistance = textWidth + widget.blankSpace;
        final fadeStop = (widget.fadeWidth / maxWidth).clamp(0.01, 0.25);

        return SizedBox(
          width: maxWidth,
          height: textPainter.height,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final offset = _controller.value * scrollDistance;
              final leftFadeActive = offset > 2.0;

              return ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      leftFadeActive ? Colors.transparent : Colors.black,
                      Colors.black,
                      Colors.black,
                      Colors.transparent,
                    ],
                    stops: [0.0, leftFadeActive ? fadeStop : 0.0, 1.0 - fadeStop, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: ClipRect(
                  child: OverflowBox(
                    minWidth: 0,
                    maxWidth: double.infinity,
                    alignment: Alignment.centerLeft,
                    child: Transform.translate(
                      offset: Offset(-offset, 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(widget.text, style: effectiveStyle, maxLines: 1),
                          SizedBox(width: widget.blankSpace),
                          Text(widget.text, style: effectiveStyle, maxLines: 1),
                          SizedBox(width: widget.blankSpace),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
