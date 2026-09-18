import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../enum.dart';
import '../../theme.dart';

/// Botanical artwork for a species.
///
/// The specification calls for photographic cut-outs on transparent
/// backgrounds, bottom-aligned so the subject stands on the card. Until those
/// assets are supplied per species, each entry is drawn as its signature
/// silhouette over the same pale ground, which is how the design's own cards
/// are composed.
class PlantArtwork extends StatelessWidget {
  const PlantArtwork({
    super.key,
    required this.glyph,
    this.ground = GroundPalette.mint,
    this.showGround = true,
    this.inset = 0.12,
    this.alignment = Alignment.bottomCenter,
    this.tint,
    this.opacity = 1,
  });

  final PlantGlyph glyph;
  final GroundPalette ground;

  /// When false the silhouette is drawn straight onto the parent's surface.
  final bool showGround;

  /// Fraction of the box left clear around the silhouette.
  final double inset;
  final Alignment alignment;

  /// Overrides the silhouette colour — used on dark hero surfaces.
  final Color? tint;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final art = Opacity(
      opacity: opacity,
      child: CustomPaint(
        painter: _PlantGlyphPainter(
          glyph: glyph,
          inset: inset,
          alignment: alignment,
          tint: tint,
        ),
        size: Size.infinite,
      ),
    );
    if (!showGround) return art;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: ground == GroundPalette.mint ? AppColors.mint : AppColors.sage,
        ),
      ),
      child: art,
    );
  }
}

class _PlantGlyphPainter extends CustomPainter {
  const _PlantGlyphPainter({
    required this.glyph,
    required this.inset,
    required this.alignment,
    this.tint,
  });

  final PlantGlyph glyph;
  final double inset;
  final Alignment alignment;
  final Color? tint;

  static const Color _ink = Color(0xFF2F3833);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final base = tint ?? _ink;
    // Work in a square unit box so shapes keep their proportions, then place
    // it in the available space.
    final side = math.min(size.width, size.height) * (1 - inset);
    final dx = (size.width - side) / 2 + alignment.x * (size.width - side) / 2;
    final dy = (size.height - side) / 2 + alignment.y * (size.height - side) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(side);

    switch (glyph) {
      case PlantGlyph.monstera:
        _monstera(canvas, base);
      case PlantGlyph.monsteraAdansonii:
        _adansonii(canvas, base);
      case PlantGlyph.miniMonstera:
        _miniMonstera(canvas, base);
      case PlantGlyph.peaceLily:
        _peaceLily(canvas, base);
      case PlantGlyph.snakePlant:
        _snakePlant(canvas, base);
      case PlantGlyph.fiddleLeaf:
        _fiddleLeaf(canvas, base);
      case PlantGlyph.aloe:
        _aloe(canvas, base);
      case PlantGlyph.pothos:
        _pothos(canvas, base);
      case PlantGlyph.calathea:
        _calathea(canvas, base);
      case PlantGlyph.zzPlant:
        _zzPlant(canvas, base);
      case PlantGlyph.fern:
        _fern(canvas, base);
      case PlantGlyph.rubberPlant:
        _rubberPlant(canvas, base);
    }
    canvas.restore();
  }

  // ── Primitives (unit space, 0–1) ─────────────────────────────────────────

  Paint _fill(Color c, double o) => Paint()
    ..color = c.withValues(alpha: o)
    ..isAntiAlias = true;

  /// A pointed leaf blade rising from [baseX], [baseY].
  Path _blade({
    required double baseX,
    required double baseY,
    required double length,
    required double width,
    required double angle,
    double curve = 0,
  }) {
    final path = Path();
    final dirX = math.sin(angle);
    final dirY = -math.cos(angle);
    final perpX = math.cos(angle);
    final perpY = math.sin(angle);

    final tipX = baseX + dirX * length + perpX * curve;
    final tipY = baseY + dirY * length + perpY * curve;
    final midX = baseX + dirX * length * 0.45;
    final midY = baseY + dirY * length * 0.45;

    path.moveTo(baseX, baseY);
    path.quadraticBezierTo(
      midX + perpX * width,
      midY + perpY * width,
      tipX,
      tipY,
    );
    path.quadraticBezierTo(
      midX - perpX * width,
      midY - perpY * width,
      baseX,
      baseY,
    );
    path.close();
    return path;
  }

  /// A heart-shaped leaf, as on a pothos or philodendron.
  Path _heart({
    required double cx,
    required double baseY,
    required double height,
    required double width,
    double rotation = 0,
  }) {
    final p = Path();
    final w = width / 2;
    p.moveTo(cx, baseY - height);
    p.cubicTo(cx + w * 0.95, baseY - height * 0.86, cx + w, baseY - height * 0.3,
        cx + w * 0.42, baseY - height * 0.02);
    p.cubicTo(cx + w * 0.16, baseY + height * 0.06, cx - w * 0.16,
        baseY + height * 0.06, cx - w * 0.42, baseY - height * 0.02);
    p.cubicTo(cx - w, baseY - height * 0.3, cx - w * 0.95,
        baseY - height * 0.86, cx, baseY - height);
    p.close();
    if (rotation == 0) return p;
    final m = Matrix4.identity()
      ..translateByDouble(cx, baseY, 0, 1)
      ..rotateZ(rotation)
      ..translateByDouble(-cx, -baseY, 0, 1);
    return p.transform(m.storage);
  }

  /// The monstera's shield outline with lower lobes and a notched base.
  Path _monsteraBlade(double cx, double baseY, double h, double w) {
    final p = Path();
    final hw = w / 2;
    p.moveTo(cx, baseY - h);
    p.cubicTo(cx + hw * 0.62, baseY - h * 0.94, cx + hw, baseY - h * 0.62,
        cx + hw, baseY - h * 0.34);
    p.cubicTo(cx + hw, baseY - h * 0.12, cx + hw * 0.72, baseY - h * 0.01,
        cx + hw * 0.34, baseY);
    p.lineTo(cx, baseY - h * 0.1);
    p.lineTo(cx - hw * 0.34, baseY);
    p.cubicTo(cx - hw * 0.72, baseY - h * 0.01, cx - hw, baseY - h * 0.12,
        cx - hw, baseY - h * 0.34);
    p.cubicTo(cx - hw, baseY - h * 0.62, cx - hw * 0.62, baseY - h * 0.94, cx,
        baseY - h);
    p.close();
    return p;
  }

  /// Elliptical fenestrations, angled away from the midrib.
  void _fenestrate(
    Canvas canvas,
    double cx,
    double baseY,
    double h,
    double w, {
    required Color holeColor,
  }) {
    final paint = Paint()
      ..color = holeColor
      ..isAntiAlias = true
      ..blendMode = BlendMode.dstOut;
    final rows = [0.30, 0.45, 0.60];
    for (var r = 0; r < rows.length; r++) {
      final y = baseY - h * rows[r];
      final spread = w * (0.40 - r * 0.075);
      final rw = w * (0.17 - r * 0.028);
      final rh = h * 0.045;
      for (final sign in [-1.0, 1.0]) {
        canvas.save();
        canvas.translate(cx + sign * spread, y);
        canvas.rotate(sign * 0.36);
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: rw * 2, height: rh * 2),
          paint,
        );
        canvas.restore();
      }
    }
  }

  // ── Species compositions ─────────────────────────────────────────────────

  void _monstera(Canvas canvas, Color base) {
    canvas.saveLayer(const Rect.fromLTWH(-0.2, -0.2, 1.4, 1.4), Paint());
    // Two receding leaves.
    canvas.drawPath(
        _monsteraBlade(0.19, 1.0, 0.64, 0.52), _fill(base, 0.32));
    canvas.drawPath(
        _monsteraBlade(0.82, 1.0, 0.60, 0.50), _fill(base, 0.44));
    // Foreground leaf.
    canvas.drawPath(_monsteraBlade(0.5, 1.02, 0.96, 0.78), _fill(base, 1));
    _fenestrate(canvas, 0.5, 1.02, 0.96, 0.78,
        holeColor: const Color(0xFFFFFFFF));
    canvas.restore();
  }

  void _adansonii(Canvas canvas, Color base) {
    canvas.saveLayer(const Rect.fromLTWH(-0.2, -0.2, 1.4, 1.4), Paint());
    canvas.drawPath(_heart(cx: 0.28, baseY: 0.98, height: 0.62, width: 0.5),
        _fill(base, 0.4));
    final leaf = _heart(cx: 0.56, baseY: 1.0, height: 0.86, width: 0.68);
    canvas.drawPath(leaf, _fill(base, 1));
    final cut = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..blendMode = BlendMode.dstOut
      ..isAntiAlias = true;
    for (final spec in [
      [0.44, 0.60, 0.11, 0.030],
      [0.68, 0.60, 0.11, 0.030],
      [0.40, 0.44, 0.13, 0.034],
      [0.72, 0.44, 0.13, 0.034],
      [0.46, 0.30, 0.09, 0.026],
      [0.66, 0.30, 0.09, 0.026],
    ]) {
      canvas.save();
      canvas.translate(spec[0], spec[1]);
      canvas.rotate(spec[0] < 0.56 ? -0.34 : 0.34);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero, width: spec[2] * 2, height: spec[3] * 2),
        cut,
      );
      canvas.restore();
    }
    canvas.restore();
  }

  void _miniMonstera(Canvas canvas, Color base) {
    canvas.drawPath(
        _blade(
            baseX: 0.40,
            baseY: 1.0,
            length: 0.66,
            width: 0.24,
            angle: -0.22,
            curve: -0.03),
        _fill(base, 0.4));
    canvas.drawPath(
        _blade(
            baseX: 0.54,
            baseY: 1.02,
            length: 0.86,
            width: 0.30,
            angle: 0.05,
            curve: 0.0),
        _fill(base, 1));
  }

  void _peaceLily(Canvas canvas, Color base) {
    canvas.drawPath(
        _blade(baseX: 0.5, baseY: 1.02, length: 0.62, width: 0.14, angle: -0.95),
        _fill(base, 0.42));
    canvas.drawPath(
        _blade(baseX: 0.5, baseY: 1.02, length: 0.62, width: 0.14, angle: 0.95),
        _fill(base, 0.42));
    canvas.drawPath(
        _blade(baseX: 0.5, baseY: 1.02, length: 0.80, width: 0.15, angle: -0.48),
        _fill(base, 0.62));
    canvas.drawPath(
        _blade(baseX: 0.5, baseY: 1.02, length: 0.80, width: 0.15, angle: 0.48),
        _fill(base, 0.62));
    // The spathe: a dark blade carrying a pale spadix.
    final spathe =
        _blade(baseX: 0.5, baseY: 1.02, length: 0.96, width: 0.17, angle: 0.12);
    canvas.drawPath(spathe, _fill(base, 1));
    canvas.drawOval(
      Rect.fromCenter(
          center: const Offset(0.585, 0.44), width: 0.085, height: 0.135),
      _fill(const Color(0xFFFFFFFF), 0.95),
    );
  }

  void _snakePlant(Canvas canvas, Color base) {
    canvas.drawPath(
        _blade(baseX: 0.5, baseY: 1.02, length: 0.66, width: 0.085, angle: -0.62),
        _fill(base, 0.38));
    canvas.drawPath(
        _blade(baseX: 0.5, baseY: 1.02, length: 0.70, width: 0.085, angle: 0.62),
        _fill(base, 0.38));
    canvas.drawPath(
        _blade(baseX: 0.5, baseY: 1.02, length: 0.84, width: 0.095, angle: -0.30),
        _fill(base, 0.66));
    canvas.drawPath(
        _blade(baseX: 0.5, baseY: 1.02, length: 0.88, width: 0.095, angle: 0.30),
        _fill(base, 0.66));
    canvas.drawPath(
        _blade(baseX: 0.5, baseY: 1.02, length: 1.0, width: 0.105, angle: 0.02),
        _fill(base, 1));
  }

  void _fiddleLeaf(Canvas canvas, Color base) {
    canvas.drawPath(
        _heart(cx: 0.33, baseY: 0.98, height: 0.62, width: 0.54),
        _fill(base, 0.34));
    canvas.drawPath(
        _heart(cx: 0.69, baseY: 0.98, height: 0.60, width: 0.52),
        _fill(base, 0.46));
    final leaf = Path()
      ..moveTo(0.5, 0.04)
      ..cubicTo(0.86, 0.18, 0.94, 0.54, 0.74, 0.86)
      ..cubicTo(0.64, 1.0, 0.36, 1.0, 0.26, 0.86)
      ..cubicTo(0.06, 0.54, 0.14, 0.18, 0.5, 0.04)
      ..close();
    canvas.drawPath(leaf, _fill(base, 1));
    canvas.drawLine(
      const Offset(0.5, 0.1),
      const Offset(0.5, 0.95),
      Paint()
        ..color = const Color(0xFF2C3A26)
        ..strokeWidth = 0.014
        ..isAntiAlias = true,
    );
  }

  void _aloe(Canvas canvas, Color base) {
    const specs = [
      [-1.05, 0.62, 0.36],
      [1.05, 0.62, 0.36],
      [-0.66, 0.78, 0.5],
      [0.66, 0.78, 0.5],
      [-0.30, 0.92, 0.72],
      [0.30, 0.92, 0.72],
      [0.0, 1.0, 1.0],
    ];
    for (final s in specs) {
      canvas.drawPath(
        _blade(
          baseX: 0.5,
          baseY: 1.02,
          length: s[1],
          width: 0.085 + (1 - s[2]) * 0.02,
          angle: s[0],
          curve: s[0] * 0.02,
        ),
        _fill(base, s[2]),
      );
    }
  }

  void _pothos(Canvas canvas, Color base) {
    canvas.drawPath(
        _heart(cx: 0.36, baseY: 0.99, height: 0.66, width: 0.58, rotation: -0.18),
        _fill(base, 0.42));
    canvas.drawPath(
        _heart(cx: 0.66, baseY: 1.0, height: 0.80, width: 0.66, rotation: 0.12),
        _fill(base, 1));
  }

  void _calathea(Canvas canvas, Color base) {
    canvas.drawPath(
        _blade(baseX: 0.5, baseY: 1.02, length: 0.72, width: 0.24, angle: -0.6),
        _fill(base, 0.36));
    canvas.drawPath(
        _blade(baseX: 0.5, baseY: 1.02, length: 0.76, width: 0.24, angle: 0.6),
        _fill(base, 0.36));
    canvas.drawOval(
      Rect.fromCenter(
          center: const Offset(0.5, 0.42), width: 0.62, height: 0.74),
      _fill(base, 1),
    );
    canvas.drawLine(
      const Offset(0.5, 0.1),
      const Offset(0.5, 1.0),
      Paint()
        ..color = const Color(0xFF2C3A26)
        ..strokeWidth = 0.012,
    );
  }

  void _zzPlant(Canvas canvas, Color base) {
    for (final stem in [
      [0.34, -0.34, 0.74, 0.5],
      [0.66, 0.34, 0.74, 0.5],
      [0.5, 0.0, 0.92, 1.0],
    ]) {
      final angle = stem[1];
      final len = stem[2];
      final opacity = stem[3];
      final baseX = stem[0];
      canvas.drawLine(
        Offset(baseX, 1.0),
        Offset(baseX + math.sin(angle) * len, 1.0 - math.cos(angle) * len),
        Paint()
          ..color = base.withValues(alpha: opacity)
          ..strokeWidth = 0.022
          ..strokeCap = StrokeCap.round,
      );
      for (var i = 1; i <= 4; i++) {
        final t = i / 4.6;
        final x = baseX + math.sin(angle) * len * t;
        final y = 1.0 - math.cos(angle) * len * t;
        for (final sign in [-1.0, 1.0]) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(x + sign * 0.075, y - 0.02),
              width: 0.15,
              height: 0.085,
            ),
            _fill(base, opacity),
          );
        }
      }
    }
  }

  void _fern(Canvas canvas, Color base) {
    for (final frond in [
      [-0.85, 0.66, 0.34],
      [0.85, 0.66, 0.34],
      [-0.45, 0.82, 0.55],
      [0.45, 0.82, 0.55],
      [0.0, 0.96, 1.0],
    ]) {
      final angle = frond[0];
      final len = frond[1];
      final opacity = frond[2];
      final tipX = 0.5 + math.sin(angle) * len;
      final tipY = 1.0 - math.cos(angle) * len;
      canvas.drawLine(
        const Offset(0.5, 1.0),
        Offset(tipX, tipY),
        Paint()
          ..color = base.withValues(alpha: opacity)
          ..strokeWidth = 0.016
          ..strokeCap = StrokeCap.round,
      );
      for (var i = 1; i <= 6; i++) {
        final t = i / 7;
        final x = 0.5 + (tipX - 0.5) * t;
        final y = 1.0 + (tipY - 1.0) * t;
        final size = 0.085 * (1 - t * 0.55);
        for (final sign in [-1.0, 1.0]) {
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(angle + sign * 0.9);
          canvas.drawOval(
            Rect.fromCenter(
                center: Offset(0, -size), width: size * 0.9, height: size * 2),
            _fill(base, opacity),
          );
          canvas.restore();
        }
      }
    }
  }

  void _rubberPlant(Canvas canvas, Color base) {
    canvas.drawPath(
        _blade(baseX: 0.46, baseY: 1.02, length: 0.66, width: 0.2, angle: -0.5),
        _fill(base, 0.38));
    canvas.drawPath(
        _blade(baseX: 0.54, baseY: 1.02, length: 0.72, width: 0.2, angle: 0.5),
        _fill(base, 0.52));
    canvas.drawPath(
        _blade(baseX: 0.5, baseY: 1.04, length: 0.98, width: 0.26, angle: 0.02),
        _fill(base, 1));
  }

  @override
  bool shouldRepaint(_PlantGlyphPainter old) =>
      old.glyph != glyph ||
      old.inset != inset ||
      old.alignment != alignment ||
      old.tint != tint;
}
