import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../theme.dart';

/// The icon family from the Foundations page.
///
/// One family, 1.6px stroke on a 24px grid, round caps and joins. Leaf green
/// marks the active state; everything else is mono. No emoji, no filled
/// glyphs.
enum PgIcons {
  home,
  grid,
  scan,
  chart,
  person,
  search,
  droplet,
  dropletDouble,
  sun,
  sunLow,
  thermometer,
  leaf,
  bell,
  calendar,
  camera,
  cloud,
  cloudRain,
  moon,
  wind,
  lock,
  star,
  pin,
  clock,
  image,
  flash,
  refresh,
  check,
  close,
  plus,
  minus,
  chevronLeft,
  chevronRight,
  chevronDown,
  arrowRight,
  sliders,
  dots,
  bookmark,
  share,
  pencil,
  alertTriangle,
  alertCircle,
  searchAlert,
  wifiOff,
  pause,
  mail,
  eye,
  eyeOff,
  help,
  info,
  google,
  apple,
}

/// Draws a [PgIcons] glyph.
class PgIcon extends StatelessWidget {
  const PgIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.color = AppColors.ink,
    this.strokeWidth,
  });

  final PgIcons icon;
  final double size;
  final Color color;

  /// Defaults to 1.6 on the 24px grid, scaled with [size].
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _PgIconPainter(
          icon: icon,
          color: color,
          strokeWidth: strokeWidth ?? 1.6 * (size / 24),
        ),
      ),
    );
  }
}

class _PgIconPainter extends CustomPainter {
  const _PgIconPainter({
    required this.icon,
    required this.color,
    required this.strokeWidth,
  });

  final PgIcons icon;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    Offset p(double x, double y) => Offset(x * s, y * s);

    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(p(x1, y1), p(x2, y2), paint);

    void circle(double cx, double cy, double r) =>
        canvas.drawCircle(p(cx, cy), r * s, paint);

    void dot(double cx, double cy, double r) => canvas.drawCircle(
        p(cx, cy), r * s, Paint()..color = color..isAntiAlias = true);

    void rrect(double x, double y, double w, double h, double r) =>
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x * s, y * s, w * s, h * s),
            Radius.circular(r * s),
          ),
          paint,
        );

    void path(void Function(Path) build) {
      final pth = Path();
      build(pth);
      canvas.drawPath(pth, paint);
    }

    switch (icon) {
      case PgIcons.home:
        path((pt) {
          pt.moveTo(3.2 * s, 10.4 * s);
          pt.lineTo(12 * s, 3.4 * s);
          pt.lineTo(20.8 * s, 10.4 * s);
          pt.lineTo(20.8 * s, 19 * s);
          pt.arcToPoint(p(19, 20.8),
              radius: Radius.circular(1.8 * s), clockwise: true);
          pt.lineTo(5 * s, 20.8 * s);
          pt.arcToPoint(p(3.2, 19),
              radius: Radius.circular(1.8 * s), clockwise: true);
          pt.close();
        });
        path((pt) {
          pt.moveTo(9.4 * s, 20.8 * s);
          pt.lineTo(9.4 * s, 14.2 * s);
          pt.lineTo(14.6 * s, 14.2 * s);
          pt.lineTo(14.6 * s, 20.8 * s);
        });

      case PgIcons.grid:
        rrect(3.4, 3.4, 7.2, 7.2, 2);
        rrect(13.4, 3.4, 7.2, 7.2, 2);
        rrect(3.4, 13.4, 7.2, 7.2, 2);
        rrect(13.4, 13.4, 7.2, 7.2, 2);

      case PgIcons.scan:
        const c = 6.0;
        path((pt) {
          pt.moveTo(3.2 * s, (3.2 + c) * s);
          pt.lineTo(3.2 * s, 5.6 * s);
          pt.arcToPoint(p(5.6, 3.2),
              radius: Radius.circular(2.4 * s), clockwise: true);
          pt.lineTo((3.2 + c) * s, 3.2 * s);
        });
        path((pt) {
          pt.moveTo((20.8 - c) * s, 3.2 * s);
          pt.lineTo(18.4 * s, 3.2 * s);
          pt.arcToPoint(p(20.8, 5.6),
              radius: Radius.circular(2.4 * s), clockwise: true);
          pt.lineTo(20.8 * s, (3.2 + c) * s);
        });
        path((pt) {
          pt.moveTo(20.8 * s, (20.8 - c) * s);
          pt.lineTo(20.8 * s, 18.4 * s);
          pt.arcToPoint(p(18.4, 20.8),
              radius: Radius.circular(2.4 * s), clockwise: true);
          pt.lineTo((20.8 - c) * s, 20.8 * s);
        });
        path((pt) {
          pt.moveTo((3.2 + c) * s, 20.8 * s);
          pt.lineTo(5.6 * s, 20.8 * s);
          pt.arcToPoint(p(3.2, 18.4),
              radius: Radius.circular(2.4 * s), clockwise: true);
          pt.lineTo(3.2 * s, (20.8 - c) * s);
        });

      case PgIcons.chart:
        path((pt) {
          pt.moveTo(2.8 * s, 16.6 * s);
          pt.lineTo(7.6 * s, 9.6 * s);
          pt.lineTo(11.4 * s, 14.6 * s);
          pt.lineTo(16 * s, 7.8 * s);
          pt.lineTo(21.2 * s, 16.6 * s);
        });

      case PgIcons.person:
        circle(12, 8.2, 3.8);
        path((pt) {
          pt.moveTo(4.6 * s, 20.6 * s);
          pt.cubicTo(5.4 * s, 16.4 * s, 8.4 * s, 14.4 * s, 12 * s, 14.4 * s);
          pt.cubicTo(15.6 * s, 14.4 * s, 18.6 * s, 16.4 * s, 19.4 * s, 20.6 * s);
        });

      case PgIcons.search:
        circle(10.6, 10.6, 6.6);
        line(15.4, 15.4, 20.6, 20.6);

      case PgIcons.searchAlert:
        circle(10.6, 10.6, 6.6);
        line(15.4, 15.4, 20.6, 20.6);
        line(10.6, 7.6, 10.6, 11);
        dot(10.6, 13.4, 0.85);

      case PgIcons.droplet:
        path((pt) {
          pt.moveTo(12 * s, 2.8 * s);
          pt.cubicTo(12 * s, 2.8 * s, 4.8 * s, 10.4 * s, 4.8 * s, 14.6 * s);
          pt.arcToPoint(p(19.2, 14.6),
              radius: Radius.circular(7.2 * s), clockwise: false);
          pt.cubicTo(19.2 * s, 10.4 * s, 12 * s, 2.8 * s, 12 * s, 2.8 * s);
          pt.close();
        });

      case PgIcons.dropletDouble:
        void small(double cx, double top, double scale) {
          path((pt) {
            pt.moveTo(cx * s, top * s);
            pt.cubicTo(cx * s, top * s, (cx - 4 * scale) * s,
                (top + 4.6 * scale) * s, (cx - 4 * scale) * s,
                (top + 7.2 * scale) * s);
            pt.arcToPoint(p(cx + 4 * scale, top + 7.2 * scale),
                radius: Radius.circular(4 * scale * s), clockwise: false);
            pt.cubicTo((cx + 4 * scale) * s, (top + 4.6 * scale) * s, cx * s,
                top * s, cx * s, top * s);
            pt.close();
          });
        }
        small(8.4, 4.4, 0.78);
        small(16.0, 4.4, 0.78);

      case PgIcons.sun:
        circle(12, 12, 4.4);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          const inner = 7.2, outer = 9.8;
          line(12 + math.cos(a) * inner, 12 + math.sin(a) * inner,
              12 + math.cos(a) * outer, 12 + math.sin(a) * outer);
        }

      case PgIcons.sunLow:
        circle(12, 12, 3.2);
        for (var i = 0; i < 4; i++) {
          final a = i * math.pi / 2 + math.pi / 4;
          line(12 + math.cos(a) * 5.6, 12 + math.sin(a) * 5.6,
              12 + math.cos(a) * 7.8, 12 + math.sin(a) * 7.8);
        }
        line(12, 3.2, 12, 5.8);
        line(12, 18.2, 12, 20.8);
        line(3.2, 12, 5.8, 12);
        line(18.2, 12, 20.8, 12);

      case PgIcons.thermometer:
        circle(12, 17.4, 3.5);
        path((pt) {
          pt.moveTo(9.8 * s, 15.4 * s);
          pt.lineTo(9.8 * s, 5.9 * s);
          pt.arcToPoint(p(14.2, 5.9),
              radius: Radius.circular(2.2 * s), clockwise: true);
          pt.lineTo(14.2 * s, 15.4 * s);
        });
        line(12, 8.6, 12, 14.6);

      case PgIcons.leaf:
        path((pt) {
          pt.moveTo(19.4 * s, 4.6 * s);
          pt.cubicTo(19.4 * s, 4.6 * s, 6.4 * s, 3.4 * s, 5.2 * s, 12.6 * s);
          pt.cubicTo(4.5 * s, 18 * s, 9.2 * s, 20.6 * s, 13 * s, 19.2 * s);
          pt.cubicTo(18.4 * s, 17.2 * s, 20.6 * s, 10.4 * s, 19.4 * s, 4.6 * s);
          pt.close();
        });
        line(16.6, 7.4, 8.2, 16.6);

      case PgIcons.bell:
        path((pt) {
          pt.moveTo(6 * s, 17 * s);
          pt.lineTo(6 * s, 10.8 * s);
          pt.arcToPoint(p(18, 10.8),
              radius: Radius.circular(6 * s), clockwise: true);
          pt.lineTo(18 * s, 17 * s);
          pt.close();
        });
        line(4.4, 17, 19.6, 17);
        line(12, 3.2, 12, 4.9);
        path((pt) {
          pt.moveTo(10.2 * s, 19.6 * s);
          pt.arcToPoint(p(13.8, 19.6),
              radius: Radius.circular(1.9 * s), clockwise: false);
        });

      case PgIcons.calendar:
        rrect(3.6, 5.4, 16.8, 15, 3);
        line(3.6, 10, 20.4, 10);
        line(8.2, 3.2, 8.2, 6.6);
        line(15.8, 3.2, 15.8, 6.6);

      case PgIcons.camera:
        path((pt) {
          pt.moveTo(3.4 * s, 9.4 * s);
          pt.arcToPoint(p(6.4, 6.4),
              radius: Radius.circular(3 * s), clockwise: true);
          pt.lineTo(8.4 * s, 6.4 * s);
          pt.lineTo(9.8 * s, 4 * s);
          pt.lineTo(14.2 * s, 4 * s);
          pt.lineTo(15.6 * s, 6.4 * s);
          pt.lineTo(17.6 * s, 6.4 * s);
          pt.arcToPoint(p(20.6, 9.4),
              radius: Radius.circular(3 * s), clockwise: true);
          pt.lineTo(20.6 * s, 17 * s);
          pt.arcToPoint(p(17.6, 20),
              radius: Radius.circular(3 * s), clockwise: true);
          pt.lineTo(6.4 * s, 20 * s);
          pt.arcToPoint(p(3.4, 17),
              radius: Radius.circular(3 * s), clockwise: true);
          pt.close();
        });
        circle(12, 13, 3.6);

      case PgIcons.cloud:
        path((pt) {
          pt.moveTo(7.4 * s, 18.4 * s);
          pt.arcToPoint(p(7.2, 9.6),
              radius: Radius.circular(4.4 * s), clockwise: true);
          pt.arcToPoint(p(16.4, 8.6),
              radius: Radius.circular(5 * s), clockwise: true);
          pt.arcToPoint(p(17, 18.4),
              radius: Radius.circular(4.8 * s), clockwise: true);
          pt.close();
        });

      case PgIcons.cloudRain:
        path((pt) {
          pt.moveTo(7.4 * s, 15.4 * s);
          pt.arcToPoint(p(7.2, 7),
              radius: Radius.circular(4.2 * s), clockwise: true);
          pt.arcToPoint(p(16.2, 6.2),
              radius: Radius.circular(4.8 * s), clockwise: true);
          pt.arcToPoint(p(16.8, 15.4),
              radius: Radius.circular(4.6 * s), clockwise: true);
          pt.close();
        });
        line(8.6, 18, 7.8, 20.4);
        line(12.4, 18, 11.6, 20.4);
        line(16.2, 18, 15.4, 20.4);

      case PgIcons.moon:
        path((pt) {
          pt.moveTo(19.4 * s, 14.8 * s);
          pt.cubicTo(18.2 * s, 15.4 * s, 16.9 * s, 15.7 * s, 15.5 * s, 15.7 * s);
          pt.cubicTo(10.7 * s, 15.7 * s, 6.8 * s, 11.8 * s, 6.8 * s, 7 * s);
          pt.cubicTo(6.8 * s, 6 * s, 7 * s, 5 * s, 7.3 * s, 4.1 * s);
          pt.cubicTo(4.5 * s, 5.7 * s, 2.8 * s, 8.7 * s, 2.8 * s, 12 * s);
          pt.cubicTo(2.8 * s, 17.1 * s, 6.9 * s, 21.2 * s, 12 * s, 21.2 * s);
          pt.cubicTo(15.3 * s, 21.2 * s, 18.3 * s, 19.4 * s, 19.4 * s, 14.8 * s);
          pt.close();
        });

      case PgIcons.wind:
        path((pt) {
          pt.moveTo(3.4 * s, 8.6 * s);
          pt.lineTo(13.4 * s, 8.6 * s);
          pt.arcToPoint(p(13.4, 4.4),
              radius: Radius.circular(2.1 * s), clockwise: false);
        });
        line(3.4, 12.4, 17.4, 12.4);
        path((pt) {
          pt.moveTo(6.4 * s, 16.2 * s);
          pt.lineTo(14.6 * s, 16.2 * s);
          pt.arcToPoint(p(14.6, 20.4),
              radius: Radius.circular(2.1 * s), clockwise: true);
        });

      case PgIcons.lock:
        rrect(4.6, 10.4, 14.8, 10, 3);
        path((pt) {
          pt.moveTo(8 * s, 10.4 * s);
          pt.lineTo(8 * s, 7.6 * s);
          pt.arcToPoint(p(16, 7.6),
              radius: Radius.circular(4 * s), clockwise: true);
          pt.lineTo(16 * s, 10.4 * s);
        });

      case PgIcons.star:
        path((pt) {
          const r1 = 8.6, r2 = 3.7;
          for (var i = 0; i < 10; i++) {
            final r = i.isEven ? r1 : r2;
            final a = -math.pi / 2 + i * math.pi / 5;
            final x = 12 + math.cos(a) * r;
            final y = 12 + math.sin(a) * r;
            if (i == 0) {
              pt.moveTo(x * s, y * s);
            } else {
              pt.lineTo(x * s, y * s);
            }
          }
          pt.close();
        });

      case PgIcons.pin:
        path((pt) {
          pt.moveTo(12 * s, 21 * s);
          pt.cubicTo(12 * s, 21 * s, 19 * s, 14.6 * s, 19 * s, 9.8 * s);
          pt.arcToPoint(p(5, 9.8),
              radius: Radius.circular(7 * s), clockwise: false);
          pt.cubicTo(5 * s, 14.6 * s, 12 * s, 21 * s, 12 * s, 21 * s);
          pt.close();
        });
        circle(12, 9.8, 2.7);

      case PgIcons.clock:
        circle(12, 12, 8.6);
        path((pt) {
          pt.moveTo(12 * s, 6.8 * s);
          pt.lineTo(12 * s, 12 * s);
          pt.lineTo(15.8 * s, 14 * s);
        });

      case PgIcons.image:
        rrect(3.4, 4.6, 17.2, 14.8, 3.4);
        circle(8.8, 9.8, 1.7);
        path((pt) {
          pt.moveTo(4.2 * s, 17.4 * s);
          pt.lineTo(9.6 * s, 12.6 * s);
          pt.lineTo(13.4 * s, 16 * s);
          pt.lineTo(16.4 * s, 13.4 * s);
          pt.lineTo(20 * s, 16.6 * s);
        });

      case PgIcons.flash:
        path((pt) {
          pt.moveTo(13.4 * s, 2.6 * s);
          pt.lineTo(5.4 * s, 13.4 * s);
          pt.lineTo(11.4 * s, 13.4 * s);
          pt.lineTo(10.6 * s, 21.4 * s);
          pt.lineTo(18.6 * s, 10.6 * s);
          pt.lineTo(12.6 * s, 10.6 * s);
          pt.close();
        });

      case PgIcons.refresh:
        path((pt) {
          pt.addArc(
            Rect.fromCircle(center: p(12, 12), radius: 7.6 * s),
            -math.pi * 0.72,
            math.pi * 1.45,
          );
        });
        path((pt) {
          pt.moveTo(15.6 * s, 3.4 * s);
          pt.lineTo(17.8 * s, 6.6 * s);
          pt.lineTo(14.2 * s, 7.6 * s);
        });

      case PgIcons.check:
        path((pt) {
          pt.moveTo(5 * s, 12.6 * s);
          pt.lineTo(10 * s, 17.4 * s);
          pt.lineTo(19 * s, 6.8 * s);
        });

      case PgIcons.close:
        line(6, 6, 18, 18);
        line(18, 6, 6, 18);

      case PgIcons.plus:
        line(12, 5, 12, 19);
        line(5, 12, 19, 12);

      case PgIcons.minus:
        line(5, 12, 19, 12);

      case PgIcons.chevronLeft:
        path((pt) {
          pt.moveTo(14.8 * s, 5.4 * s);
          pt.lineTo(8.6 * s, 12 * s);
          pt.lineTo(14.8 * s, 18.6 * s);
        });

      case PgIcons.chevronRight:
        path((pt) {
          pt.moveTo(9.2 * s, 5.4 * s);
          pt.lineTo(15.4 * s, 12 * s);
          pt.lineTo(9.2 * s, 18.6 * s);
        });

      case PgIcons.chevronDown:
        path((pt) {
          pt.moveTo(5.4 * s, 9.2 * s);
          pt.lineTo(12 * s, 15.4 * s);
          pt.lineTo(18.6 * s, 9.2 * s);
        });

      case PgIcons.arrowRight:
        line(3.8, 12, 19.6, 12);
        path((pt) {
          pt.moveTo(13.8 * s, 6 * s);
          pt.lineTo(19.8 * s, 12 * s);
          pt.lineTo(13.8 * s, 18 * s);
        });

      case PgIcons.dots:
        dot(5.6, 12, 1.7);
        dot(12, 12, 1.7);
        dot(18.4, 12, 1.7);

      case PgIcons.sliders:
        line(3.4, 7.4, 20.6, 7.4);
        line(3.4, 16.6, 20.6, 16.6);
        circle(9, 7.4, 2.5);
        circle(15.6, 16.6, 2.5);

      case PgIcons.bookmark:
        path((pt) {
          pt.moveTo(6.2 * s, 3.6 * s);
          pt.lineTo(17.8 * s, 3.6 * s);
          pt.lineTo(17.8 * s, 20.4 * s);
          pt.lineTo(12 * s, 15.8 * s);
          pt.lineTo(6.2 * s, 20.4 * s);
          pt.close();
        });

      case PgIcons.share:
        line(12, 3.6, 12, 14.8);
        path((pt) {
          pt.moveTo(7.6 * s, 8 * s);
          pt.lineTo(12 * s, 3.6 * s);
          pt.lineTo(16.4 * s, 8 * s);
        });
        path((pt) {
          pt.moveTo(5.4 * s, 12.6 * s);
          pt.lineTo(5.4 * s, 19 * s);
          pt.arcToPoint(p(8.4, 21.4),
              radius: Radius.circular(3 * s), clockwise: false);
          pt.lineTo(15.6 * s, 21.4 * s);
          pt.arcToPoint(p(18.6, 19),
              radius: Radius.circular(3 * s), clockwise: false);
          pt.lineTo(18.6 * s, 12.6 * s);
        });

      case PgIcons.pencil:
        path((pt) {
          pt.moveTo(4.4 * s, 19.6 * s);
          pt.lineTo(5.2 * s, 15.4 * s);
          pt.lineTo(15.8 * s, 4.8 * s);
          pt.lineTo(19.2 * s, 8.2 * s);
          pt.lineTo(8.6 * s, 18.8 * s);
          pt.close();
        });

      case PgIcons.alertTriangle:
        path((pt) {
          pt.moveTo(12 * s, 3.8 * s);
          pt.lineTo(21.4 * s, 19.6 * s);
          pt.lineTo(2.6 * s, 19.6 * s);
          pt.close();
        });
        line(12, 9.6, 12, 14);
        dot(12, 16.8, 0.9);

      case PgIcons.alertCircle:
        circle(12, 12, 8.8);
        line(12, 7.2, 12, 12.6);
        dot(12, 15.8, 0.9);

      case PgIcons.info:
        circle(12, 12, 8.8);
        line(12, 11.2, 12, 16.4);
        dot(12, 8.2, 0.9);

      case PgIcons.help:
        circle(12, 12, 8.8);
        path((pt) {
          pt.moveTo(9.4 * s, 9.6 * s);
          pt.arcToPoint(p(12.4, 12.8),
              radius: Radius.circular(2.7 * s), clockwise: true);
          pt.lineTo(12 * s, 14.4 * s);
        });
        dot(12, 17, 0.85);

      case PgIcons.wifiOff:
        path((pt) {
          pt.moveTo(6.4 * s, 12.6 * s);
          pt.arcToPoint(p(11, 10.6),
              radius: Radius.circular(5.6 * s), clockwise: true);
        });
        path((pt) {
          pt.moveTo(9.4 * s, 16 * s);
          pt.arcToPoint(p(14.6, 16),
              radius: Radius.circular(3.2 * s), clockwise: true);
        });
        path((pt) {
          pt.moveTo(3.2 * s, 9.2 * s);
          pt.arcToPoint(p(8.6, 6),
              radius: Radius.circular(9.4 * s), clockwise: true);
        });
        path((pt) {
          pt.moveTo(15.2 * s, 6.8 * s);
          pt.arcToPoint(p(20.8, 9.2),
              radius: Radius.circular(9.4 * s), clockwise: true);
        });
        dot(12, 19.4, 0.95);
        line(3.6, 3.6, 20.4, 20.4);

      case PgIcons.pause:
        rrect(8.2, 6.6, 2.6, 10.8, 1.3);
        rrect(13.2, 6.6, 2.6, 10.8, 1.3);

      case PgIcons.mail:
        rrect(3.2, 5.2, 17.6, 13.6, 3.2);
        path((pt) {
          pt.moveTo(4.4 * s, 7.4 * s);
          pt.lineTo(12 * s, 13 * s);
          pt.lineTo(19.6 * s, 7.4 * s);
        });

      case PgIcons.eye:
        path((pt) {
          pt.moveTo(2.4 * s, 12 * s);
          pt.cubicTo(5 * s, 7 * s, 8.4 * s, 4.8 * s, 12 * s, 4.8 * s);
          pt.cubicTo(15.6 * s, 4.8 * s, 19 * s, 7 * s, 21.6 * s, 12 * s);
          pt.cubicTo(19 * s, 17 * s, 15.6 * s, 19.2 * s, 12 * s, 19.2 * s);
          pt.cubicTo(8.4 * s, 19.2 * s, 5 * s, 17 * s, 2.4 * s, 12 * s);
          pt.close();
        });
        circle(12, 12, 3.4);

      case PgIcons.eyeOff:
        path((pt) {
          pt.moveTo(4 * s, 8.6 * s);
          pt.cubicTo(2.9 * s, 9.6 * s, 2 * s, 10.7 * s, 1.6 * s, 12 * s);
          pt.cubicTo(4.2 * s, 17 * s, 7.8 * s, 19.2 * s, 12 * s, 19.2 * s);
          pt.cubicTo(13.6 * s, 19.2 * s, 15.1 * s, 18.9 * s, 16.4 * s, 18.3 * s);
        });
        path((pt) {
          pt.moveTo(8.6 * s, 5.6 * s);
          pt.cubicTo(9.7 * s, 5.1 * s, 10.8 * s, 4.8 * s, 12 * s, 4.8 * s);
          pt.cubicTo(16.2 * s, 4.8 * s, 19.8 * s, 7 * s, 22.4 * s, 12 * s);
          pt.cubicTo(21.6 * s, 13.6 * s, 20.6 * s, 14.9 * s, 19.5 * s, 16 * s);
        });
        line(3.4, 3.4, 20.6, 20.6);

      case PgIcons.google:
        _paintGoogle(canvas, s);

      case PgIcons.apple:
        _paintApple(canvas, s, color);
    }
  }

  /// The Google mark keeps its own colours; it is a brand asset, not part of
  /// the mono icon family.
  void _paintGoogle(Canvas canvas, double s) {
    final rect = Rect.fromCircle(center: Offset(12 * s, 12 * s), radius: 8.4 * s);
    final stroke = 4.4 * s;
    void arc(double start, double sweep, Color c) {
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = c
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..isAntiAlias = true,
      );
    }

    arc(-math.pi * 0.28, math.pi * 0.52, const Color(0xFFEA4335));
    arc(math.pi * 0.24, math.pi * 0.54, const Color(0xFFFBBC05));
    arc(math.pi * 0.78, math.pi * 0.52, const Color(0xFF34A853));
    arc(-math.pi * 0.74, math.pi * 0.46, const Color(0xFF4285F4));
    canvas.drawRect(
      Rect.fromLTWH(12 * s, 9.9 * s, 8.8 * s, 4.2 * s),
      Paint()..color = const Color(0xFF4285F4),
    );
    canvas.drawRect(
      Rect.fromLTWH(11.6 * s, 9.9 * s, 2.2 * s, 4.2 * s),
      Paint()..color = const Color(0x00000000),
    );
  }

  void _paintApple(Canvas canvas, double s, Color c) {
    final fill = Paint()
      ..color = c
      ..isAntiAlias = true;
    final body = Path()
      ..moveTo(12 * s, 7.4 * s)
      ..cubicTo(13.6 * s, 6.2 * s, 16 * s, 6.3 * s, 17.4 * s, 7.8 * s)
      ..cubicTo(15.6 * s, 9 * s, 15.8 * s, 11.8 * s, 17.8 * s, 12.8 * s)
      ..cubicTo(17.2 * s, 14.9 * s, 15.6 * s, 17.8 * s, 14 * s, 18.4 * s)
      ..cubicTo(13 * s, 18.8 * s, 12.6 * s, 18.2 * s, 11.6 * s, 18.2 * s)
      ..cubicTo(10.6 * s, 18.2 * s, 10.1 * s, 18.8 * s, 9.2 * s, 18.4 * s)
      ..cubicTo(7.2 * s, 17.6 * s, 5.4 * s, 13.4 * s, 6.2 * s, 10.6 * s)
      ..cubicTo(6.8 * s, 8.5 * s, 8.6 * s, 7.2 * s, 10.2 * s, 7.2 * s)
      ..cubicTo(11 * s, 7.2 * s, 11.5 * s, 7.4 * s, 12 * s, 7.4 * s)
      ..close();
    canvas.drawPath(body, fill);
    final leaf = Path()
      ..moveTo(12.6 * s, 6.2 * s)
      ..cubicTo(12.4 * s, 4.6 * s, 13.8 * s, 3.2 * s, 15.2 * s, 3.2 * s)
      ..cubicTo(15.4 * s, 4.8 * s, 14 * s, 6.2 * s, 12.6 * s, 6.2 * s)
      ..close();
    canvas.drawPath(leaf, fill);
  }

  @override
  bool shouldRepaint(_PgIconPainter old) =>
      old.icon != icon || old.color != color || old.strokeWidth != strokeWidth;
}
