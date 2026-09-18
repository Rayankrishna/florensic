import 'package:flutter/material.dart';

import '../../domain/models/plant.dart';
import '../../domain/models/plant_species.dart';
import '../../enum.dart';
import '../../key.dart';
import '../../theme.dart';
import '../widgets/plant_artwork.dart';
import 'app_chip.dart';
import 'pressable.dart';

/// A collection card: artwork over a pale ground, the score in a pill, then
/// the name, botanical name and status line.
class PlantCard extends StatelessWidget {
  const PlantCard({super.key, required this.plant, this.onTap});

  final Plant plant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = plant.statusLine;
    return Pressable(
      onTap: onTap,
      semanticLabel: '${plant.nickname}, ${status.label}',
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardR,
          boxShadow: AppShadows.raised,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: AppKeys.plantHero(plant.id),
                    child: PlantArtwork(
                      glyph: plant.species.glyph,
                      ground: plant.species.ground,
                      inset: 0.08,
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.md,
                    right: AppSpacing.md,
                    child: _ScoreBadge(score: plant.healthScore),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.md, AppSpacing.lg + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.heading20.copyWith(fontSize: 17.5),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    plant.latinName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body13.copyWith(fontSize: 12.5),
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),
                  StatusLine(
                    label: status.label,
                    tone: status.status,
                    isWater: status.isWater,
                    fontSize: 12.5,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int? score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.pillR,
      ),
      child: Text(
        score?.toString() ?? '—',
        style: AppText.heading17.copyWith(
          fontSize: 16,
          color: score == null
              ? AppColors.inkMuted
              : switch (HealthBandX.fromScore(score)) {
                  HealthBand.thriving => AppColors.healthyDeep,
                  HealthBand.watch => AppColors.cautionDeep,
                  HealthBand.critical => AppColors.criticalDeep,
                  HealthBand.paused => AppColors.inkMuted,
                },
        ),
      ),
    );
  }
}

/// A Pokedex card: catalogue number over the artwork, then the names and two
/// compact trait chips.
class SpeciesCard extends StatelessWidget {
  const SpeciesCard({super.key, required this.species, this.onTap});

  final PlantSpecies species;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: '${species.commonName}, ${species.latinName}',
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardR,
          boxShadow: AppShadows.raised,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: AppKeys.speciesHero(species.id),
                    child: PlantArtwork(
                      glyph: species.glyph,
                      ground: species.ground,
                      inset: 0.08,
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.md + 2,
                    left: AppSpacing.lg,
                    child: Text(
                      '№ ${species.number.toString().padLeft(3, '0')}',
                      style: AppText.label13.copyWith(
                        fontSize: 12,
                        color: AppColors.inkMuted,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    species.commonName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.heading20.copyWith(fontSize: 17.5),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    species.latinName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body13.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      TagPill(
                        label: species.difficulty,
                        dense: true,
                        tone: switch (species.difficulty) {
                          'Easy' => MetricStatus.good,
                          'Medium' => MetricStatus.watch,
                          _ => MetricStatus.bad,
                        },
                      ),
                      TagPill(
                        label: species.shortLight,
                        dense: true,
                        tone: MetricStatus.neutral,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
