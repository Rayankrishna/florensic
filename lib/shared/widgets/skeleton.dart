import 'package:flutter/material.dart';

import '../../theme.dart';

/// A shimmering placeholder block.
///
/// The design's loading state keeps the real layout and greys the content, so
/// the page does not jump when data arrives.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
    this.shape = BoxShape.rectangle,
  });

  const Skeleton.circle({super.key, required double size})
      : width = size,
        height = size,
        radius = 0,
        shape = BoxShape.circle;

  final double? width;
  final double height;
  final double radius;
  final BoxShape shape;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.rectangle
                ? BorderRadius.circular(widget.radius)
                : null,
            gradient: LinearGradient(
              begin: Alignment(-1 - t * 2, 0),
              end: Alignment(1 - t * 2, 0),
              colors: const [
                Color(0xFFE7EEEB),
                Color(0xFFF3F8F6),
                Color(0xFFE7EEEB),
              ],
              stops: const [0.25, 0.5, 0.75],
            ),
          ),
        );
      },
    );
  }
}

/// The My Plants loading state: header placeholders, a calculating card, then
/// skeleton plant cards.
class PlantsSkeleton extends StatelessWidget {
  const PlantsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Skeleton(width: 130, height: 14),
        SizedBox(height: AppSpacing.xxl),
        Row(
          children: [
            Expanded(child: Skeleton(height: 62, radius: AppRadius.pill)),
            SizedBox(width: AppSpacing.md),
            Skeleton.circle(size: 62),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Skeleton(width: 74, height: 44, radius: AppRadius.pill),
            SizedBox(width: AppSpacing.md),
            Skeleton(width: 96, height: 44, radius: AppRadius.pill),
            SizedBox(width: AppSpacing.md),
            Skeleton(width: 108, height: 44, radius: AppRadius.pill),
          ],
        ),
        SizedBox(height: AppSpacing.xl),
        _CalculatingCard(),
        SizedBox(height: AppSpacing.xl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _CardSkeleton()),
            SizedBox(width: AppSpacing.lg),
            Expanded(child: _CardSkeleton()),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _CardSkeleton()),
            SizedBox(width: AppSpacing.lg),
            Expanded(child: _CardSkeleton()),
          ],
        ),
      ],
    );
  }
}

class _CalculatingCard extends StatelessWidget {
  const _CalculatingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardR,
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 104,
            height: 104,
            child: _SpinnerRing(),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Skeleton(height: 12, width: 120),
                const SizedBox(height: AppSpacing.md),
                const Skeleton(height: 12),
                const SizedBox(height: AppSpacing.md),
                const Skeleton(height: 12, width: 100),
                const SizedBox(height: AppSpacing.lg),
                Text('Calculating health…',
                    style: AppText.label13
                        .copyWith(fontSize: 14, color: AppColors.inkMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpinnerRing extends StatefulWidget {
  const _SpinnerRing();

  @override
  State<_SpinnerRing> createState() => _SpinnerRingState();
}

class _SpinnerRingState extends State<_SpinnerRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _c,
      child: const CircularProgressIndicator(
        strokeWidth: 9,
        strokeCap: StrokeCap.round,
        value: 0.22,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.leaf),
        backgroundColor: AppColors.track,
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.cardR,
      child: Container(
        color: AppColors.surface,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton(height: 140, radius: 0),
            Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(width: 110, height: 13),
                  SizedBox(height: AppSpacing.sm + 2),
                  Skeleton(width: 140, height: 11),
                  SizedBox(height: AppSpacing.sm + 2),
                  Skeleton(width: 90, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
