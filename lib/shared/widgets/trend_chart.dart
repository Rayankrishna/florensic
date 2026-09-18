import 'package:flutter/widgets.dart';

import '../../domain/models/plant_health.dart';
import '../../theme.dart';

/// The health trend chart: an ink line over a lime gradient wash, with a
/// lime-cored marker on the most recent reading.
class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.points,
    required this.labels,
    this.height = 190,
    this.animate = true,
  });

  final List<HealthPoint> points;
  final List<String> labels;
  final double height;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return SizedBox(height: height);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: animate ? 0 : 1, end: 1),
            duration: animate
                ? const Duration(milliseconds: 900)
                : Duration.zero,
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => CustomPaint(
              painter: _TrendPainter(points: points, progress: t),
              size: Size.infinite,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: labels.length > 3
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.spaceBetween,
          children: [
            for (final l in labels)
              Text(l, style: AppText.body13.copyWith(fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({required this.points, required this.progress});

  final List<HealthPoint> points;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final scores = points.map((p) => p.score).toList();
    final min = scores.reduce((a, b) => a < b ? a : b);
    final max = scores.reduce((a, b) => a > b ? a : b);
    final span = (max - min) < 8 ? 8.0 : (max - min).toDouble();
    final low = min - span * 0.28;
    final high = max + span * 0.22;

    double xFor(int i) => size.width * i / (points.length - 1);
    double yFor(int score) =>
        size.height * (1 - (score - low) / (high - low)) * 0.92 + size.height * 0.04;

    // Gridlines.
    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (final f in [0.08, 0.42, 0.76]) {
      canvas.drawLine(
        Offset(0, size.height * f),
        Offset(size.width, size.height * f),
        grid,
      );
    }

    final line = Path();
    for (var i = 0; i < points.length; i++) {
      final o = Offset(xFor(i), yFor(points[i].score));
      if (i == 0) {
        line.moveTo(o.dx, o.dy);
      } else {
        line.lineTo(o.dx, o.dy);
      }
    }

    // Reveal the line left-to-right.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));

    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x997CB342), Color(0x087CB342)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
    canvas.restore();

    if (progress > 0.97) {
      final last = Offset(xFor(points.length - 1), yFor(points.last.score));
      canvas.drawCircle(last, 9, Paint()..color = AppColors.ink);
      canvas.drawCircle(last, 5.4, Paint()..color = AppColors.leaf);
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.progress != progress || old.points != points;
}

/// The environmental history chart: a solid amber temperature line and a
/// dotted blue humidity line.
class DualSeriesChart extends StatelessWidget {
  const DualSeriesChart({
    super.key,
    required this.primary,
    required this.secondary,
    required this.labels,
    this.height = 180,
    this.animate = true,
  });

  final List<double> primary;
  final List<double> secondary;
  final List<String> labels;
  final double height;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (primary.length < 2) return SizedBox(height: height);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: animate ? 0 : 1, end: 1),
            duration:
                animate ? const Duration(milliseconds: 900) : Duration.zero,
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => CustomPaint(
              painter: _DualPainter(
                primary: primary,
                secondary: secondary,
                progress: t,
              ),
              size: Size.infinite,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final l in labels)
              Text(l, style: AppText.body13.copyWith(fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

class _DualPainter extends CustomPainter {
  const _DualPainter({
    required this.primary,
    required this.secondary,
    required this.progress,
  });

  final List<double> primary;
  final List<double> secondary;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (final f in [0.1, 0.5, 0.9]) {
      canvas.drawLine(Offset(0, size.height * f),
          Offset(size.width, size.height * f), grid);
    }

    List<Offset> mapSeries(List<double> values, double top, double bottom) {
      final min = values.reduce((a, b) => a < b ? a : b);
      final max = values.reduce((a, b) => a > b ? a : b);
      final span = (max - min) < 1 ? 1.0 : max - min;
      return [
        for (var i = 0; i < values.length; i++)
          Offset(
            size.width * i / (values.length - 1),
            bottom - (values[i] - min) / span * (bottom - top),
          ),
      ];
    }

    final tempPts = mapSeries(primary, size.height * 0.22, size.height * 0.80);
    final humPts = mapSeries(secondary, size.height * 0.14, size.height * 0.62);

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));

    // Humidity — dotted.
    final dotPaint = Paint()
      ..color = AppColors.water
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < humPts.length - 1; i++) {
      _dashedLine(canvas, humPts[i], humPts[i + 1], dotPaint);
    }

    // Temperature — solid.
    final path = Path()..moveTo(tempPts.first.dx, tempPts.first.dy);
    for (final o in tempPts.skip(1)) {
      path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.caution
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
    canvas.restore();

    if (progress > 0.97) {
      canvas.drawCircle(tempPts.last, 6.4, Paint()..color = AppColors.caution);
    }
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 1.0;
    const gap = 7.0;
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    var t = 0.0;
    while (t < total) {
      final start = a + dir * t;
      final end = a + dir * (t + dash).clamp(0, total);
      canvas.drawLine(start, end, paint);
      t += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DualPainter old) => old.progress != progress;
}
