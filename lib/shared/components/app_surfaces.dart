import 'package:flutter/material.dart';

import '../../theme.dart';

/// A white card: 28px radius, 20–24px padding, wide green-tinted shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.radius = AppRadius.card,
    this.color = AppColors.surface,
    this.elevated = true,
    this.border,
    this.clip = false,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final bool elevated;

  /// Never combined with [elevated] — the spec forbids border + shadow.
  final Border? border;
  final bool clip;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: border == null && elevated ? AppShadows.raised : null,
      ),
      child: child,
    );
  }
}

/// A tinted card with no shadow — care tips, advisory rows, soft insights.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    required this.color,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.radius = AppRadius.card,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}

/// An ink card carrying a soft radial glow, as used for the environmental
/// insight, the weather panel and the next-watering hero.
class DarkCard extends StatelessWidget {
  const DarkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPaddingLarge),
    this.radius = AppRadius.card,
    this.glow = AppColors.leaf,
    this.glowAlignment = const Alignment(0.75, -0.7),
    this.glowRadius = 0.85,
    this.glowOpacity = 0.30,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color glow;
  final Alignment glowAlignment;
  final double glowRadius;
  final double glowOpacity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadows.raised,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: glowAlignment,
                    radius: glowRadius,
                    colors: [
                      glow.withValues(alpha: glowOpacity),
                      glow.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// The app ground plus the lime glow that sits behind the top of most screens.
class ScreenBackground extends StatelessWidget {
  const ScreenBackground({
    super.key,
    required this.child,
    this.glow = true,
    this.glowAlignment = const Alignment(0.55, -1.0),
    this.glowColor = const Color(0xFFCDE3B2),
    this.glowRadius = 0.9,
    this.glowOpacity = 0.55,
  });

  final Widget child;
  final bool glow;
  final Alignment glowAlignment;
  final Color glowColor;
  final double glowRadius;
  final double glowOpacity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.ground),
      child: Stack(
        children: [
          if (glow)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: glowAlignment,
                      radius: glowRadius,
                      colors: [
                        glowColor.withValues(alpha: glowOpacity),
                        glowColor.withValues(alpha: 0),
                      ],
                      stops: const [0, 1],
                    ),
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// A row whose children all take the height of the tallest one.
///
/// Plain `CrossAxisAlignment.stretch` cannot be used inside a scroll view —
/// the row has no bounded height there — so the intrinsic pass supplies it.
class EqualHeightRow extends StatelessWidget {
  const EqualHeightRow({
    super.key,
    required this.children,
    this.spacing = AppSpacing.lg,
  });

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}
