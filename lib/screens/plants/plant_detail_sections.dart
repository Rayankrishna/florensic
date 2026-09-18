import 'package:flutter/material.dart';

import '../../domain/models/plant.dart';
import '../../enum.dart';
import '../../locator.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_chip.dart';
import '../../shared/components/app_surfaces.dart';
import '../../shared/components/app_text_field.dart';
import '../../shared/components/headers.dart';
import '../../shared/components/list_rows.dart';
import '../../shared/components/pressable.dart';
import '../../shared/widgets/health_ring.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../shared/widgets/plant_artwork.dart';
import '../../stores/plant_collection_store.dart';
import '../../stores/plant_detail_store.dart';
import '../../theme.dart';
import '../../utils/date_format.dart';

/// The full score card, shown while a plant is thriving.
class FullHealthCard extends StatelessWidget {
  const FullHealthCard({super.key, required this.store});

  final PlantDetailStore store;

  @override
  Widget build(BuildContext context) {
    final score = store.healthScore ?? 0;
    final change = store.weeklyChange;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.cardPaddingLarge,
          AppSpacing.xxxl, AppSpacing.cardPaddingLarge, AppSpacing.cardPadding),
      child: Column(
        children: [
          HealthRing(
            score: score,
            size: 224,
            strokeWidth: 17,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScore(
                  value: score,
                  style: AppText.metric.copyWith(fontSize: 57.5),
                ),
                const SizedBox(height: 2),
                Text('PLANT HEALTH',
                    style: AppText.caption12
                        .copyWith(fontSize: 11.5, letterSpacing: 1.9)),
                const SizedBox(height: AppSpacing.md),
                TagPill(
                  label: store.bandLabel,
                  tone: MetricStatus.good,
                  dense: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Based on recent condition updates, care activity, and '
            'environmental conditions.',
            textAlign: TextAlign.center,
            style: AppText.body15.copyWith(fontSize: 15),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: AppSpacing.xl),
          StatRow(
            stats: [
              (
                label: '7-day change',
                value: change >= 0 ? '+$change' : '$change',
                valueColor:
                    change >= 0 ? AppColors.healthyDeep : AppColors.criticalDeep,
              ),
              (
                label: 'Streak',
                value: '${store.streakWeeks} weeks',
                valueColor: null
              ),
              (
                label: 'Updates',
                value: '${store.updateCount}',
                valueColor: null
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The compact score card, shown when a plant needs attention.
class AttentionHealthCard extends StatelessWidget {
  const AttentionHealthCard({super.key, required this.store});

  final PlantDetailStore store;

  @override
  Widget build(BuildContext context) {
    final score = store.healthScore ?? 0;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HealthRing(
            score: score,
            size: 132,
            strokeWidth: 13,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScore(
                  value: score,
                  style: AppText.metric.copyWith(fontSize: 35.5),
                ),
                Text('HEALTH',
                    style: AppText.caption12
                        .copyWith(fontSize: 11.5, letterSpacing: 1.6)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TagPill(
                  label: 'Needs attention',
                  tone: MetricStatus.watch,
                  dense: true,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(store.attentionHeadline,
                    style: AppText.title28.copyWith(fontSize: 22.5)),
                const SizedBox(height: AppSpacing.sm),
                Text(store.attentionBody,
                    style: AppText.body15.copyWith(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The paused card: the score is held, not estimated.
class PausedHealthCard extends StatelessWidget {
  const PausedHealthCard({super.key, required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.cardPaddingLarge,
          AppSpacing.xxxl, AppSpacing.cardPaddingLarge, AppSpacing.xxxl),
      child: Column(
        children: [
          HealthRing(
            score: null,
            size: 214,
            strokeWidth: 15,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PgIcon(PgIcons.pause, size: 34, color: AppColors.inkMuted),
                const SizedBox(height: AppSpacing.sm),
                Text('PAUSED',
                    style: AppText.caption12
                        .copyWith(fontSize: 12, letterSpacing: 2.2)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const TagPill(label: 'Care status paused', tone: MetricStatus.neutral),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Your scheduled condition update was missed. Add a new update to '
            'resume active care — your history and streak are kept.',
            textAlign: TextAlign.center,
            style: AppText.body15.copyWith(fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class WhatStillWorksCard extends StatelessWidget {
  const WhatStillWorksCard({super.key, this.photoCount = 11});

  final int photoCount;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What still works',
              style: AppText.heading20.copyWith(fontSize: 20.5)),
          const SizedBox(height: AppSpacing.xl),
          const _Bullet(
            icon: PgIcons.check,
            tone: MetricStatus.good,
            label: 'Watering reminders keep running',
          ),
          const SizedBox(height: AppSpacing.lg),
          _Bullet(
            icon: PgIcons.check,
            tone: MetricStatus.good,
            label: 'All $photoCount past photos are safe',
          ),
          const SizedBox(height: AppSpacing.lg),
          const _Bullet(
            icon: PgIcons.close,
            tone: MetricStatus.neutral,
            label: 'Health score pauses until the next update',
            muted: true,
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({
    required this.icon,
    required this.tone,
    required this.label,
    this.muted = false,
  });

  final PgIcons icon;
  final MetricStatus tone;
  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconTile(icon: icon, tone: tone, size: 44, radius: 14),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              label,
              style: AppText.body15Ink.copyWith(
                fontSize: 16,
                color: muted ? AppColors.inkMuted : AppColors.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class UnavailableTrendCard extends StatelessWidget {
  const UnavailableTrendCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: const Color(0xFFE8EFED),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.tile),
            ),
            child: const PgIcon(PgIcons.chart, size: 24, color: AppColors.ink),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plant health data unavailable',
                    style: AppText.heading17.copyWith(fontSize: 16.5)),
                const SizedBox(height: 3),
                Text(
                  'Trends need at least one update in the last 30 days. The '
                  'chart returns as soon as you add one.',
                  style: AppText.body13.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The horizontal strip of past condition photos, with a `+n` overflow tile.
class ConditionHistoryStrip extends StatelessWidget {
  const ConditionHistoryStrip({super.key, required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    const visible = 3;
    final overflow = plant.photoCount - visible;
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: visible + (overflow > 0 ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          if (index == visible) {
            return Container(
              width: 104,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.tile),
                boxShadow: AppShadows.raised,
              ),
              child: Text('+$overflow',
                  style: AppText.heading20.copyWith(fontSize: 18.5)),
            );
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.tile),
            child: SizedBox(
              width: 104,
              child: PlantArtwork(
                glyph: plant.species.glyph,
                ground: index.isEven
                    ? plant.species.ground
                    : (plant.species.ground == GroundPalette.mint
                        ? GroundPalette.sage
                        : GroundPalette.mint),
                inset: 0.14,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The overflow menu on the plant header.
class PlantOptionsSheet extends StatelessWidget {
  const PlantOptionsSheet({
    super.key,
    required this.plant,
    required this.onSchedule,
    required this.onRemove,
  });

  final Plant plant;
  final VoidCallback onSchedule;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.ground,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.track,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              TileRow(
                icon: PgIcons.calendar,
                title: 'Care schedule',
                detail: 'Watering rhythm, reminders and history',
                onTap: onSchedule,
                trailing: const PgIcon(PgIcons.chevronRight,
                    size: 20, color: AppColors.inkMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              TileRow(
                icon: PgIcons.alertCircle,
                title: 'Remove from collection',
                detail: 'In your collection since '
                    '${AppDate.dayMonth(plant.addedOn)}',
                tone: MetricStatus.bad,
                onTap: onRemove,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

/// `Remove Fiddle Leaf Fig?` — the destructive confirmation sheet.
Future<void> showRemovePlantSheet(BuildContext context, Plant plant) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8C0B1A0F),
    isScrollControlled: true,
    builder: (sheetContext) => _RemovePlantSheet(plant: plant),
  );
}

class _RemovePlantSheet extends StatefulWidget {
  const _RemovePlantSheet({required this.plant});

  final Plant plant;

  @override
  State<_RemovePlantSheet> createState() => _RemovePlantSheetState();
}

class _RemovePlantSheetState extends State<_RemovePlantSheet> {
  bool _keepPhotos = false;

  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.ground,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.track,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.tile),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: PlantArtwork(
                        glyph: plant.species.glyph,
                        ground: plant.species.ground,
                        inset: 0.16,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Remove ${plant.nickname}?',
                            style: AppText.title28.copyWith(fontSize: 23)),
                        const SizedBox(height: 3),
                        Text(
                          'In your collection since '
                          '${AppDate.dayMonth(plant.addedOn)}',
                          style: AppText.body15.copyWith(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This removes its schedule, health score and '
                      '${plant.photoCount} condition photos. The Pokedex entry '
                      'stays available.',
                      style: AppText.body15Ink.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        AppCheckbox(
                          value: _keepPhotos,
                          onChanged: (v) => setState(() => _keepPhotos = v),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text('Keep the photos in my library',
                              style: AppText.body15.copyWith(fontSize: 15)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: AppButton.outline(
                      label: 'Keep it',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      label: 'Remove',
                      style: AppButtonStyle.danger,
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await locator<PlantCollectionStore>()
                            .removePlant(plant.id);
                        navigator.pop();
                        navigator.popUntil((route) => route.isFirst);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A pressable wrapper kept here so sections can share the press feel.
class SectionTap extends StatelessWidget {
  const SectionTap({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Pressable(onTap: onTap, child: child);
}

/// Re-exported so the dashboard can title its sections consistently.
typedef DetailSectionHeader = SectionHeader;
