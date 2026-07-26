import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A circular progress ring with the percentage in the middle.
///
/// Used on the lending score card; generic enough for any 0–1 value.
class ScoreRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final TextStyle? labelStyle;

  const ScoreRing({
    super.key,
    required this.progress,
    this.size = 62,
    this.strokeWidth = 6,
    this.color = Colors.white,
    this.trackColor = Colors.white24,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: clamped,
          strokeWidth: strokeWidth,
          color: color,
          trackColor: trackColor,
        ),
        child: Center(
          child: Text(
            '${(clamped * 100).round()}%',
            style: labelStyle ??
                TextStyle(
                  color: color,
                  fontSize: size * 0.24,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;
  final Color trackColor;

  const _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(centre, radius, track);

    // Start at 12 o'clock and sweep clockwise.
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}
