import 'package:flutter/material.dart';

import '../../domain/models/plant_health.dart';
import '../../enum.dart';
import '../../theme.dart';
import '../widgets/pg_icon.dart';
import 'app_surfaces.dart';

/// One tile in the 2×2 metric grid: an icon, a status dot, then label, value
/// and detail.
class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.metric, this.index = 0});

  final HealthMetric metric;

  /// Position in the grid, used to stagger the entrance.
  final int index;

  static PgIcons iconFor(MetricKind kind) => switch (kind) {
        MetricKind.watering => PgIcons.droplet,
        MetricKind.light => PgIcons.sun,
        MetricKind.environment => PgIcons.thermometer,
        MetricKind.condition => PgIcons.camera,
      };

  static Color colorFor(MetricStatus status) => switch (status) {
        MetricStatus.good => const Color(0xFF3E9B49),
        MetricStatus.watch => AppColors.caution,
        MetricStatus.bad => AppColors.critical,
        MetricStatus.neutral => AppColors.inkFaint,
      };

  static Color iconColorFor(MetricKind kind, MetricStatus status) {
    if (status == MetricStatus.bad) return AppColors.criticalDeep;
    return switch (kind) {
      MetricKind.watering => AppColors.waterDeep,
      MetricKind.light => AppColors.cautionDeep,
      MetricKind.environment => AppColors.ink,
      MetricKind.condition => AppColors.ink,
    };
  }

  @override
  Widget build(BuildContext context) {
    return _StaggeredEntrance(
      index: index,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                PgIcon(
                  iconFor(metric.kind),
                  size: 22,
                  color: iconColorFor(metric.kind, metric.status),
                ),
                const Spacer(),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colorFor(metric.status),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(metric.label, style: AppText.body15.copyWith(fontSize: 14)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              metric.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.heading20.copyWith(fontSize: 19.5),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              metric.detail,
              style: AppText.body13.copyWith(
                fontSize: 13,
                color: metric.status == MetricStatus.bad
                    ? AppColors.criticalDeep
                    : AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A short, once-only rise used for grids and lists.
class _StaggeredEntrance extends StatelessWidget {
  const _StaggeredEntrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + index * 70),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 14), child: child),
      ),
      child: child,
    );
  }
}

/// A short entrance wrapper available to screens.
class Entrance extends StatelessWidget {
  const Entrance({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 16,
  });

  final Widget child;
  final int index;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child:
            Transform.translate(offset: Offset(0, (1 - t) * offset), child: child),
      ),
      child: child,
    );
  }
}
