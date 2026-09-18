import 'package:flutter/material.dart';

import '../../domain/models/plant.dart';
import '../../enum.dart';
import '../../routes.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/pressable.dart';
import '../../shared/widgets/plant_artwork.dart';
import '../../theme.dart';

/// A card in the home `Needs attention` carousel.
///
/// The first card carries the lime fill; the rest are white, so the carousel
/// reads as one urgent item followed by the queue behind it.
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
    final Color bodyColor =
        onLeaf ? const Color(0xFF2C3B20) : AppColors.inkMuted;

    return Pressable(
      onTap: () => Navigator.of(context)
          .pushNamed(AppRoutes.plantDetail, arguments: plant),
      semanticLabel: '${plant.nickname} — ${status.label}',
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.raised,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -30,
              bottom: -46,
              width: 158,
              height: 162,
              child: PlantArtwork(
                glyph: plant.species.glyph,
                showGround: false,
                tint: onLeaf ? const Color(0xFF25341B) : null,
                opacity: onLeaf ? 0.85 : 0.9,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusPill(
                    label: _pillLabel(status),
                    onLeaf: onLeaf,
                    tone: status.status,
                    isWater: status.isWater,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    plant.nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title28.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: SizedBox(
                      width: 150,
                      child: Text(
                        _body(plant),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body15
                            .copyWith(fontSize: 14, color: bodyColor),
                      ),
                    ),
                  ),
                  AppButton(
                    label: needsUpdate ? 'Update now' : 'View plant',
                    style: onLeaf ? AppButtonStyle.dark : AppButtonStyle.outline,
                    height: 48,
                    expand: false,
                    fontSize: 14,
                    onPressed: () {
                      if (needsUpdate) {
                        Navigator.of(context).pushNamed(
                            AppRoutes.conditionUpdate,
                            arguments: plant);
                      } else {
                        Navigator.of(context).pushNamed(AppRoutes.plantDetail,
                            arguments: plant);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _pillLabel(PlantStatusLine status) {
    if (status.isWater) return 'Watering recommended';
    return status.label;
  }

  static String _body(Plant plant) {
    if (plant.conditionDue) {
      return 'Keep your care status active with a fresh photo.';
    }
    if (plant.daysUntilWatering < 0) {
      return 'Watering is ${-plant.daysUntilWatering} days past its schedule.';
    }
    if (plant.waterDue) {
      return 'Warm weather may increase water demand.';
    }
    if (plant.leafDropReported) {
      return 'Recent updates report leaf drop. Check light and moisture.';
    }
    return 'Open the dashboard for the full picture.';
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
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 9),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pillR),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.label13.copyWith(fontSize: 13, color: fg),
      ),
    );
  }
}
