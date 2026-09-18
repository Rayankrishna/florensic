import 'package:flutter/material.dart';

import '../../theme.dart';
import '../widgets/pg_icon.dart';
import 'app_button.dart';

/// Empty states always offer the next action, never a dead end.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.body,
    this.artwork,
    this.icon = PgIcons.leaf,
    this.primaryLabel,
    this.onPrimary,
    this.primaryIcon,
    this.secondaryLabel,
    this.onSecondary,
    this.compact = false,
  });

  final String title;
  final String body;

  /// Replaces the dashed-circle icon with bespoke artwork.
  final Widget? artwork;
  final PgIcons icon;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final PgIcons? primaryIcon;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: artwork ??
              _DashedCircle(
                size: compact ? 120 : 210,
                child: PgIcon(icon,
                    size: compact ? 34 : 48, color: AppColors.inkMuted),
              ),
        ),
        SizedBox(height: compact ? AppSpacing.xl : AppSpacing.xxxl),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppText.title28.copyWith(fontSize: compact ? 20 : 28),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 0 : AppSpacing.md),
          child: Text(
            body,
            textAlign: TextAlign.center,
            style: AppText.body15.copyWith(fontSize: compact ? 14 : 16),
          ),
        ),
        if (primaryLabel != null) ...[
          SizedBox(height: compact ? AppSpacing.xl : AppSpacing.xxxl),
          AppButton.primary(
            label: primaryLabel!,
            onPressed: onPrimary,
            icon: primaryIcon,
          ),
        ],
        if (secondaryLabel != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppButton.outline(label: secondaryLabel!, onPressed: onSecondary),
        ],
      ],
    );
  }
}

class _DashedCircle extends StatelessWidget {
  const _DashedCircle({required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: const _DashedCirclePainter(),
        child: Center(
          child: Container(
            width: size * 0.82,
            height: size * 0.82,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.mint,
              ),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final r = size.width / 2 - 1;
    const segments = 56;
    for (var i = 0; i < segments; i++) {
      if (i.isOdd) continue;
      final start = i * 2 * 3.14159265 / segments;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: r),
        start,
        2 * 3.14159265 / segments * 0.9,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => false;
}
