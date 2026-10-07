import 'package:flutter/material.dart';

import '../../domain/models/plant.dart';
import '../../enum.dart';
import '../../routes.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/pressable.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../shared/widgets/plant_artwork.dart';
import '../../theme.dart';

/// A row in the home `Needs attention` list.
///
/// The list is vertical so every plant that wants something is visible at
/// once rather than hidden off the side of a carousel. The first row keeps
/// the leaf fill, so the most urgent item still leads.
class HomeAttentionCard extends StatelessWidget {
  const HomeAttentionCard({
    super.key,
    required this.plant,
    this.highlighted = false,
  });

  final Plant plant;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final status = plant.statusLine;
    final needsUpdate = plant.conditionDue;
    final onLeaf = highlighted;

    final Color background = onLeaf ? AppColors.leaf : AppColors.surface;
    final Color bodyColor = onLeaf
        ? const Color(0xFF2C3B20)
        : AppColors.inkMuted;

    void open() => Navigator.of(
      context,
    ).pushNamed(AppRoutes.plantDetail, arguments: plant);

    void act() => Navigator.of(context).pushNamed(
      needsUpdate ? AppRoutes.conditionUpdate : AppRoutes.plantDetail,
      arguments: plant,
    );

    return Pressable(
      onTap: open,
      semanticLabel: '${plant.nickname} — ${status.label}',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.raised,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.tile),
              child: SizedBox(
                width: 56,
                height: 56,
                child: onLeaf
                    ? ColoredBox(
                        color: Colors.white.withValues(alpha: 0.30),
                        child: PlantArtwork(
                          glyph: plant.species.glyph,
                          showGround: false,
                          tint: const Color(0xFF25341B),
                          inset: 0.14,
                        ),
                      )
                    : PlantArtwork(
                        glyph: plant.species.glyph,
                        ground: plant.species.ground,
                        inset: 0.14,
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatusPill(
                    label: _pillLabel(status),
                    onLeaf: onLeaf,
                    tone: status.status,
                    isWater: status.isWater,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    plant.nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.heading20.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _body(plant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body13.copyWith(
                      fontSize: 12.5,
                      height: 1.3,
                      color: bodyColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            CircleIconButton(
              icon: needsUpdate ? PgIcons.camera : PgIcons.chevronRight,
              size: 40,
              background: onLeaf ? AppColors.ink : AppColors.neutralTint,
              foreground: onLeaf ? AppColors.leaf : AppColors.ink,
              elevated: false,
              onPressed: act,
              semanticLabel: needsUpdate
                  ? 'Update condition'
                  : 'View ${plant.nickname}',
            ),
          ],
        ),
      ),
    );
  }

  /// The row is narrower than the carousel card it replaced, so the pill
  /// carries the plant's own short status rather than a longer restatement.
  static String _pillLabel(PlantStatusLine status) => status.label;

  static String _body(Plant plant) {
    if (plant.conditionDue) {
      return 'A fresh photo keeps care active.';
    }
    if (plant.daysUntilWatering < 0) {
      return '${-plant.daysUntilWatering} days past its schedule.';
    }
    if (plant.waterDue) {
      return 'Warm weather may raise demand.';
    }
    if (plant.leafDropReported) {
      return 'Leaf drop reported — check light.';
    }
    return 'Open the dashboard for detail.';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.onLeaf,
    required this.tone,
    required this.isWater,
  });

  final String label;
  final bool onLeaf;
  final MetricStatus tone;
  final bool isWater;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (onLeaf) {
      bg = AppColors.ink;
      fg = AppColors.leaf;
    } else if (isWater) {
      bg = AppColors.waterTint;
      fg = AppColors.waterDeep;
    } else {
      bg = switch (tone) {
        MetricStatus.bad => AppColors.criticalTint,
        MetricStatus.watch => AppColors.cautionTint,
        MetricStatus.good => AppColors.softGreen,
        MetricStatus.neutral => AppColors.neutralTint,
      };
      fg = switch (tone) {
        MetricStatus.bad => AppColors.criticalDeep,
        MetricStatus.watch => AppColors.cautionDeep,
        MetricStatus.good => AppColors.healthyDeep,
        MetricStatus.neutral => AppColors.inkMuted,
      };
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: 4,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pillR),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.label13.copyWith(fontSize: 11.5, color: fg),
      ),
    );
  }
}
