import 'package:flutter/material.dart';

import '../../enum.dart';
import '../../shared/widgets/health_ring.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../shared/widgets/plant_artwork.dart';
import '../../theme.dart';

/// The five onboarding heroes. Each is its own composition, but they share a
/// floating-chip vocabulary and the same entrance timing.
class OnboardingHero extends StatelessWidget {
  const OnboardingHero({super.key, required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return switch (step) {
      0 => const _CollectionHero(),
      1 => const _NeedsHero(),
      2 => const _HealthHero(),
      3 => const _RemindersHero(),
      _ => const _DiscoverHero(),
    };
  }
}

/// A chip that floats over the artwork, entering with a short rise.
class _FloatingChip extends StatelessWidget {
  const _FloatingChip({
    required this.child,
    required this.delayMs,
    this.dark = false,
    this.padding = const EdgeInsets.fromLTRB(12, 12, AppSpacing.xl, 12),
  });

  final Widget child;
  final int delayMs;
  final bool dark;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return _Rise(
      delayMs: delayMs,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: dark
              ? AppColors.ink
              : Colors.white.withValues(alpha: 0.92),
          borderRadius: AppRadius.pillR,
          boxShadow: AppShadows.raised,
        ),
        child: child,
      ),
    );
  }
}

class _Rise extends StatelessWidget {
  const _Rise({required this.child, required this.delayMs, this.offset = 20});

  final Widget child;
  final int delayMs;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 520 + delayMs),
      curve: Interval(
        delayMs / (520 + delayMs),
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
            offset: Offset(0, (1 - t) * offset), child: child),
      ),
      child: child,
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({
    required this.title,
    this.subtitle,
  }) : dark = false;

  final String title;
  final String? subtitle;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title,
            style: AppText.heading17.copyWith(
                fontSize: 16, color: dark ? Colors.white : AppColors.ink)),
        if (subtitle != null)
          Text(subtitle!,
              style: AppText.body13.copyWith(
                fontSize: 14,
                color: dark ? Colors.white70 : AppColors.inkMuted,
              )),
      ],
    );
  }
}

// ── 1 · Meet your plants ───────────────────────────────────────────────────

class _CollectionHero extends StatelessWidget {
  const _CollectionHero();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFDDF2C0), Color(0xFFE9F5DD), AppColors.ground],
              stops: [0, 0.6, 1],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Image.asset('assets/images/tree_canopy.png',
              fit: BoxFit.cover, width: double.infinity),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 90,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00F1F7F6), AppColors.ground],
              ),
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.gutter,
          top: 112,
          child: _FloatingChip(
            delayMs: 160,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.softGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const PgIcon(PgIcons.leaf,
                      size: 22, color: AppColors.healthyDeep),
                ),
                const SizedBox(width: AppSpacing.md),
                const _ChipLabel(
                    title: 'Monstera', subtitle: 'Added to collection'),
              ],
            ),
          ),
        ),
        Positioned(
          right: AppSpacing.gutter,
          top: 212,
          child: _FloatingChip(
            delayMs: 320,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.leafSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('12',
                      style: AppText.heading17.copyWith(fontSize: 16)),
                ),
                const SizedBox(width: AppSpacing.md),
                const _ChipLabel(
                    title: 'Species kept', subtitle: 'Across 3 rooms'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── 2 · Know what they need ────────────────────────────────────────────────

class _NeedsHero extends StatelessWidget {
  const _NeedsHero();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFDDE9F2), Color(0xFFE4F0E7), AppColors.ground],
              stops: [0, 0.55, 1],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset('assets/images/tree_pine.png',
                fit: BoxFit.contain, alignment: Alignment.bottomCenter),
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 110,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00F1F7F6), AppColors.ground],
              ),
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.gutter,
          top: 110,
          child: _FloatingChip(
            delayMs: 120,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PgIcon(PgIcons.droplet,
                    size: 21, color: AppColors.waterDeep),
                const SizedBox(width: AppSpacing.md),
                Text('Water in 2 days',
                    style: AppText.heading17.copyWith(fontSize: 16)),
              ],
            ),
          ),
        ),
        Positioned(
          right: AppSpacing.gutter,
          top: 186,
          child: _FloatingChip(
            delayMs: 260,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PgIcon(PgIcons.sun, size: 21, color: AppColors.cautionDeep),
                const SizedBox(width: AppSpacing.md),
                Text('Bright indirect',
                    style: AppText.heading17.copyWith(fontSize: 16)),
              ],
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.gutter,
          top: 262,
          child: _FloatingChip(
            delayMs: 400,
            dark: true,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PgIcon(PgIcons.cloud, size: 21, color: AppColors.leaf),
                const SizedBox(width: AppSpacing.md),
                Text('Rain tomorrow · water less',
                    style: AppText.heading17
                        .copyWith(fontSize: 16, color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── 3 · Track their health ─────────────────────────────────────────────────

class _HealthHero extends StatelessWidget {
  const _HealthHero();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(decoration: BoxDecoration(color: AppColors.ink)),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.15, -0.55),
                radius: 0.85,
                colors: [Color(0x597CB342), Color(0x007CB342)],
              ),
            ),
          ),
        ),
        const Positioned(
          right: -40,
          bottom: -30,
          width: 260,
          height: 300,
          child: PlantArtwork(
            glyph: PlantGlyph.monstera,
            showGround: false,
            tint: Color(0xFF071006),
            opacity: 0.9,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter, 100, AppSpacing.gutter, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.md),
                    _Rise(
                      delayMs: 120 + i * 140,
                      offset: 28,
                      child: Container(
                        width: 72,
                        height: 84.0 + i * 20,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.lerp(const Color(0xFF27502B),
                                  const Color(0xFF7FC23F), i / 2)!,
                              Color.lerp(const Color(0xFF1C3C20),
                                  const Color(0xFF4E9231), i / 2)!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: i == 2
                              ? Border.all(color: AppColors.leaf, width: 1.6)
                              : Border.all(
                                  color: Colors.white.withValues(alpha: 0.10),
                                  width: 1),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('CONDITION HISTORY · 3 UPDATES',
                  style: AppText.caption12.copyWith(
                    fontSize: 12,
                    letterSpacing: 1.8,
                    color: Colors.white.withValues(alpha: 0.6),
                  )),
              const Spacer(),
              Row(
                children: [
                  const HealthRing(
                    score: 82,
                    size: 108,
                    strokeWidth: 11,
                    trackColor: Color(0xFF2A2A2A),
                    child: Text(
                      '82',
                      style: TextStyle(
                        fontFamily: AppText.display,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Looking good',
                            style: AppText.heading20
                                .copyWith(fontSize: 19.5, color: Colors.white)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Every photo you add sharpens the score.',
                          style: AppText.body15.copyWith(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 4 · Stay ahead of problems ─────────────────────────────────────────────

class _RemindersHero extends StatelessWidget {
  const _RemindersHero();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF9CC578), Color(0xFFDCEBC8), AppColors.ground],
              stops: [0, 0.55, 1],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 240,
          child: Opacity(
            opacity: 0.30,
            child: Image.asset('assets/images/tree_pine.png',
                fit: BoxFit.cover, alignment: Alignment.topCenter),
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 120,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00F1F7F6), AppColors.ground],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.gutter, 104, AppSpacing.gutter, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Rise(
                delayMs: 100,
                child: _NotificationCard(
                  icon: PgIcons.droplet,
                  tint: AppColors.waterTint,
                  iconColor: AppColors.waterDeep,
                  title: 'Peace Lily needs water',
                  detail: 'Today, 8:00',
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Padding(
                padding: EdgeInsets.only(left: AppSpacing.xxl),
                child: _Rise(
                  delayMs: 240,
                  child: _NotificationCard(
                    icon: PgIcons.alertTriangle,
                    tint: AppColors.cautionTint,
                    iconColor: AppColors.cautionDeep,
                    title: 'Heat wave inbound',
                    detail: 'Check moisture on tropicals',
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Padding(
                padding: EdgeInsets.only(left: 46),
                child: _Rise(
                  delayMs: 380,
                  child: _NotificationCard(
                    icon: PgIcons.camera,
                    tint: AppColors.leaf,
                    iconColor: AppColors.ink,
                    title: 'Condition update due',
                    detail: 'Monstera · 2 days left',
                    dark: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.title,
    required this.detail,
    this.dark = false,
  });

  final PgIcons icon;
  final Color tint;
  final Color iconColor;
  final String title;
  final String detail;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? AppColors.ink : Colors.white,
        borderRadius: AppRadius.cardR,
        boxShadow: AppShadows.raised,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(AppRadius.tile),
            ),
            child: PgIcon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppText.heading17.copyWith(
                        fontSize: 16,
                        color: dark ? Colors.white : AppColors.ink)),
                const SizedBox(height: 2),
                Text(detail,
                    style: AppText.body13.copyWith(
                      fontSize: 14,
                      color: dark ? Colors.white70 : AppColors.inkMuted,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 5 · Let's grow your collection ─────────────────────────────────────────

class _DiscoverHero extends StatelessWidget {
  const _DiscoverHero();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE3F3CF), Color(0xFFEDF5E9), AppColors.ground],
              stops: [0, 0.6, 1],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter, 108, AppSpacing.gutter, AppSpacing.xl),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _Rise(
                      delayMs: 80,
                      child: _TiltCard(
                        angle: -0.10,
                        dark: false,
                        child: Image.asset('assets/images/tree_canopy.png',
                            fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _Rise(
                      delayMs: 200,
                      child: _TiltCard(
                        angle: 0,
                        dark: true,
                        scale: 1.16,
                        badge: 'New',
                        child: Image.asset('assets/images/tree_pine.png',
                            fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _Rise(
                      delayMs: 320,
                      child: _TiltCard(
                        angle: 0.10,
                        dark: false,
                        child: Image.asset('assets/images/tree_pine.png',
                            fit: BoxFit.contain),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _Rise(
                delayMs: 440,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.pillR,
                    boxShadow: AppShadows.raised,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('2,400+',
                          style: AppText.heading17.copyWith(fontSize: 16.5)),
                      const SizedBox(width: AppSpacing.sm),
                      Text('species in the Pokedex',
                          style: AppText.body15.copyWith(fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TiltCard extends StatelessWidget {
  const _TiltCard({
    required this.angle,
    required this.dark,
    required this.child,
    this.scale = 1,
    this.badge,
  });

  final double angle;
  final bool dark;
  final Widget child;
  final double scale;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 100 * scale,
        height: 148 * scale,
        decoration: BoxDecoration(
          color: dark ? AppColors.ink : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.raised,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(padding: const EdgeInsets.all(10), child: child),
            if (badge != null)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 5),
                  decoration: const BoxDecoration(
                    color: AppColors.leaf,
                    borderRadius: AppRadius.pillR,
                  ),
                  child: Text(badge!,
                      style: AppText.label13.copyWith(fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
