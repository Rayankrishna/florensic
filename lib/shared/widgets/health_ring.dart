import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../enum.dart';
import '../../theme.dart';

/// The plant-health ring.
///
/// Fills clockwise from the top. Leaf green above 70, amber 40–69, coral
/// below 40.
/// A paused plant shows a beaded track instead of a fill — the score stops
/// rather than decays.
class HealthRing extends StatelessWidget {
  const HealthRing({
    super.key,
    required this.score,
    this.size = 220,
    this.strokeWidth = 16,
    this.animate = true,
    this.duration = const Duration(milliseconds: 1100),
    this.child,
    this.trackColor = AppColors.track,
  });

  /// `null` renders the paused state.
  final int? score;
  final double size;
  final double strokeWidth;
  final bool animate;
  final Duration duration;
  final Widget? child;
  final Color trackColor;

  static Color colorFor(int? score) => switch (HealthBandX.fromScore(score)) {
        HealthBand.thriving => AppColors.leaf,
        HealthBand.watch => AppColors.caution,
        HealthBand.critical => AppColors.critical,
        HealthBand.paused => const Color(0xFFC2D5C8),
      };

  @override
  Widget build(BuildContext context) {
    final target = (score ?? 0) / 100;
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: animate ? 0 : target, end: target),
        duration: animate ? duration : Duration.zero,
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return CustomPaint(
            painter: _RingPainter(
              progress: value,
              color: colorFor(score),
              trackColor: trackColor,
              strokeWidth: strokeWidth,
              beaded: score == null,
            ),
            child: Center(child: child),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    required this.beaded,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final bool beaded;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    if (beaded) {
      _paintBeads(canvas, size);
      return;
    }

    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..isAntiAlias = true,
    );

    if (progress <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0, 1),
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
  }

  void _paintBeads(Canvas canvas, Size size) {
    final r = (size.width - strokeWidth) / 2;
    final centre = Offset(size.width / 2, size.height / 2);
    const count = 34;
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    for (var i = 0; i < count; i++) {
      final a = -math.pi / 2 + i * math.pi * 2 / count;
      canvas.save();
      canvas.translate(centre.dx + math.cos(a) * r, centre.dy + math.sin(a) * r);
      canvas.rotate(a + math.pi / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: strokeWidth * 0.62,
            height: strokeWidth,
          ),
          Radius.circular(strokeWidth * 0.4),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth ||
      old.beaded != beaded;
}

/// A number that counts up to its value when it first appears.
class AnimatedScore extends StatelessWidget {
  const AnimatedScore({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 1100),
    this.animate = true,
  });

  final int value;
  final TextStyle style;
  final Duration duration;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: animate ? 0 : value.toDouble(), end: value.toDouble()),
      duration: animate ? duration : Duration.zero,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        v.round().toString(),
        style: style,
      ),
    );
  }
}
