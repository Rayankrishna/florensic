import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../domain/models/plant.dart';
import '../../enum.dart';
import '../../locator.dart';
import '../../routes.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_surfaces.dart';
import '../../shared/components/app_toast.dart';
import '../../shared/components/headers.dart';
import '../../shared/components/list_rows.dart';
import '../../shared/components/metric_card.dart';
import '../../shared/components/pressable.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../shared/widgets/trend_chart.dart';
import '../../stores/insights_store.dart';
import '../../stores/plant_detail_store.dart';
import '../../theme.dart';
import '../../utils/date_format.dart';
import 'plant_detail_sections.dart';

/// The plant health dashboard.
///
/// One screen, three states: an active plant with a full score card, a plant
/// that needs attention with a compact score and a coral insight, and a paused
/// plant whose score is held rather than estimated.
class PlantDetailScreen extends StatefulWidget {
  const PlantDetailScreen({super.key, required this.plant});

  final Plant plant;

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  late final PlantDetailStore _store = locator<PlantDetailStore>()
    ..attach(widget.plant);

  @override
  void initState() {
    super.initState();
    final insights = locator<InsightsStore>();
    if (insights.weather != null) {
      _store.setEnvironment(
        insights.environmentSummary,
        insights.environmentStatus,
      );
    }
  }

  Future<void> _water() async {
    await _store.markAsWatered();
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    AppToast.show(
      context,
      message: 'Marked as watered',
      detail:
          'Next watering moved to '
          '${AppDate.weekdayDayMonth(_store.plant!.schedule.nextWatering)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.lightOverlay,
      child: Scaffold(
        backgroundColor: AppColors.ground,
        body: Observer(
          builder: (context) {
            final plant = _store.plant;
            if (plant == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return ScreenBackground(
              glow: false,
              child: Stack(
                children: [
                  SafeArea(
                    bottom: false,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.gutter,
                            AppSpacing.lg,
                            AppSpacing.gutter,
                            0,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: NavHeader(
                              title: plant.nickname,
                              subtitle: plant.latinName,
                              onBack: () => Navigator.of(context).maybePop(),
                              trailing: CircleIconButton(
                                icon: PgIcons.dots,
                                onPressed: () => _showMenu(context, plant),
                                semanticLabel: 'Plant options',
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.gutter,
                            AppSpacing.xl,
                            AppSpacing.gutter,
                            0,
                          ),
                          sliver: SliverList.list(
                            children: [
                              if (_store.isPaused)
                                PausedHealthCard(plant: plant)
                              else if (_store.band == HealthBand.thriving)
                                FullHealthCard(store: _store)
                              else
                                AttentionHealthCard(store: _store),
                              if (_store.isPaused) ...[
                                const SizedBox(height: AppSpacing.lg),
                                const WhatStillWorksCard(),
                                const SizedBox(height: AppSpacing.lg),
                                const UnavailableTrendCard(),
                              ] else ...[
                                const SizedBox(height: AppSpacing.lg),
                                _MetricGrid(store: _store),
                                const SizedBox(height: AppSpacing.lg),
                                _TrendCard(store: _store),
                                const SizedBox(height: AppSpacing.lg),
                                _InsightCard(store: _store),
                                const SizedBox(height: AppSpacing.section),
                                const SectionHeader(title: 'Next actions'),
                                const SizedBox(height: AppSpacing.lg),
                                _NextActions(store: _store),
                                const SizedBox(height: AppSpacing.section),
                                SectionHeader(
                                  title: 'Condition history',
                                  trailing: '${plant.photoCount} photos',
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                ConditionHistoryStrip(plant: plant),
                              ],
                            ],
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height:
                                110 + MediaQuery.viewPaddingOf(context).bottom,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: _ActionBar(
                      paused: _store.isPaused,
                      busy: _store.isBusy,
                      justWatered: _store.justWatered,
                      onUpdate: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.conditionUpdate, arguments: plant),
                      onWater: _water,
                      onResume: () async {
                        await _store.resumeActiveCare();
                        if (!context.mounted) return;
                        Navigator.of(context).pushNamed(
                          AppRoutes.conditionUpdate,
                          arguments: _store.plant,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, Plant plant) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x8C0B1A0F),
      builder: (sheetContext) => PlantOptionsSheet(
        plant: plant,
        onSchedule: () {
          Navigator.of(sheetContext).pop();
          Navigator.of(
            context,
          ).pushNamed(AppRoutes.careSchedule, arguments: plant);
        },
        onRemove: () {
          Navigator.of(sheetContext).pop();
          showRemovePlantSheet(context, plant);
        },
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.store});

  final PlantDetailStore store;

  @override
  Widget build(BuildContext context) {
    final metrics = store.metrics;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.lg,
        crossAxisSpacing: AppSpacing.lg,
        mainAxisExtent: 182,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) =>
          MetricCard(metric: metrics[index], index: index),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.store});

  final PlantDetailStore store;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.cardPadding,
        AppSpacing.cardPadding,
        AppSpacing.cardPadding,
        AppSpacing.xl,
      ),
      child: Observer(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Health trend',
                    style: AppText.heading20.copyWith(fontSize: 20.5),
                  ),
                ),
                _RangeSelector(store: store),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            if (store.hasTrendData)
              TrendChart(
                key: ValueKey(store.range),
                points: store.trendSeries,
                labels: store.trendLabels,
              )
            else
              SizedBox(
                height: 160,
                child: Center(
                  child: Text(
                    'Not enough readings yet',
                    style: AppText.body15.copyWith(fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.store});

  final PlantDetailStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: AppColors.neutralTint,
        borderRadius: AppRadius.pillR,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final range in TrendRange.values)
            Pressable(
              onTap: () => store.setRange(range),
              scale: 0.95,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: store.range == range
                      ? AppColors.ink
                      : Colors.transparent,
                  borderRadius: AppRadius.pillR,
                ),
                child: Text(
                  range.label,
                  style: AppText.label13.copyWith(
                    fontSize: 13,
                    color: store.range == range
                        ? Colors.white
                        : AppColors.inkMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.store});

  final PlantDetailStore store;

  @override
  Widget build(BuildContext context) {
    final insight = store.latestInsight;
    if (insight.tone == MetricStatus.good) {
      return DarkCard(
        glowAlignment: const Alignment(0.8, -0.6),
        glowOpacity: 0.26,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CaptionLabel('Latest insight', color: AppColors.leaf),
            const SizedBox(height: AppSpacing.md),
            Text(
              insight.headline,
              style: AppText.title28.copyWith(
                fontSize: 22.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              insight.body,
              style: AppText.body15.copyWith(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.80),
              ),
            ),
          ],
        ),
      );
    }
    return SoftCard(
      color: AppColors.criticalTint,
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CaptionLabel('Latest insight', color: AppColors.criticalDeep),
          const SizedBox(height: AppSpacing.md),
          Text(insight.headline, style: AppText.title28.copyWith(fontSize: 22.5)),
          const SizedBox(height: AppSpacing.md),
          Text(
            insight.body,
            style: AppText.body15.copyWith(
              fontSize: 15,
              color: const Color(0xFF7A3524),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextActions extends StatelessWidget {
  const _NextActions({required this.store});

  final PlantDetailStore store;

  @override
  Widget build(BuildContext context) {
    final plant = store.plant!;
    final actions = store.nextActions;
    return Column(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          Entrance(
            index: i,
            child: TileRow(
              icon: MetricCard.iconFor(actions[i].kind),
              title: actions[i].title,
              detail: actions[i].detail,
              background: actions[i].highlighted
                  ? AppColors.leafSoft
                  : AppColors.surface,
              elevated: !actions[i].highlighted,
              iconBackground: switch (actions[i].kind) {
                MetricKind.watering => AppColors.waterTint,
                MetricKind.condition => AppColors.cautionTint,
                _ => const Color(0xFFDDEEC0),
              },
              iconForeground: switch (actions[i].kind) {
                MetricKind.watering => AppColors.waterDeep,
                MetricKind.condition => AppColors.cautionDeep,
                _ => AppColors.healthyDeep,
              },
              detailColor:
                  actions[i].kind == MetricKind.condition && plant.conditionDue
                  ? AppColors.cautionDeep
                  : null,
              trailing: actions[i].highlighted
                  ? null
                  : const PgIcon(
                      PgIcons.chevronRight,
                      size: 20,
                      color: AppColors.inkMuted,
                    ),
              onTap: actions[i].highlighted
                  ? null
                  : actions[i].kind == MetricKind.watering
                  ? () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.careSchedule, arguments: plant)
                  : () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.conditionUpdate, arguments: plant),
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.paused,
    required this.busy,
    required this.justWatered,
    required this.onUpdate,
    required this.onWater,
    required this.onResume,
  });

  final bool paused;
  final bool busy;
  final bool justWatered;
  final VoidCallback onUpdate;
  final VoidCallback onWater;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.xxxl,
        AppSpacing.gutter,
        MediaQuery.viewPaddingOf(context).bottom + AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00F1F7F6), AppColors.ground, AppColors.ground],
          stops: [0, 0.45, 1],
        ),
      ),
      child: paused
          ? AppButton.primary(
              label: 'Resume active care',
              loading: busy,
              onPressed: onResume,
            )
          : Row(
              children: [
                Expanded(
                  child: AppButton.dark(
                    label: 'Update condition',
                    onPressed: onUpdate,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton(
                    label: justWatered ? 'Watered' : 'Mark as watered',
                    style: justWatered
                        ? AppButtonStyle.soft
                        : AppButtonStyle.primary,
                    icon: justWatered ? PgIcons.check : null,
                    loading: busy,
                    onPressed: onWater,
                  ),
                ),
              ],
            ),
    );
  }
}
