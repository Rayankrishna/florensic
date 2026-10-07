import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../domain/models/plant.dart';
import '../../domain/models/plant_health.dart';
import '../../enum.dart';
import '../../locator.dart';
import '../../routes.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_surfaces.dart';
import '../../shared/components/app_toast.dart';
import '../../shared/components/care_sheets.dart';
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
/// One screen, several states: a thriving plant with a full score card, one
/// that needs attention (or has gone quiet) with a compact score, one nothing
/// has scored yet, and a paused plant whose last score is held.
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
    _store.loadCourses();
  }

  Future<void> _water() async {
    await _store.markAsWatered();
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    // Watering is care given; it moves the schedule, never the score.
    AppToast.show(
      context,
      message: 'Marked as watered',
      detail:
          'Next watering moved to '
          '${AppDate.weekdayDayMonth(_store.plant!.schedule.nextWatering)}',
    );
  }

  Future<void> _skipWater() async {
    final skipped = await showWaterSkipSheet(
      context,
      onSkip: _store.skipWatering,
    );
    if (!mounted) return;
    if (skipped) {
      AppToast.show(
        context,
        message: 'Watering skipped',
        detail: 'Next watering '
            '${AppDate.weekdayDayMonth(_store.plant!.schedule.nextWatering)}',
      );
    } else if (_store.errorMessage != null) {
      AppToast.show(context, message: _store.errorMessage!);
    }
  }

  Future<void> _addNote() async {
    final saved = await showQuickNoteSheet(
      context,
      onSave: (chips, text) => _store.addNote(chips, text: text),
    );
    if (!mounted) return;
    if (saved) {
      AppToast.show(
        context,
        message: 'Note saved',
        detail: 'Next check-in opens '
            '${AppDate.weekdayDayMonth(_store.plant!.schedule.checkInWindowOpens)}',
      );
    } else if (_store.errorMessage != null) {
      AppToast.show(context, message: _store.errorMessage!);
    }
  }

  void _checkIn(Plant plant) => Navigator.of(context)
      .pushNamed(AppRoutes.conditionUpdate, arguments: plant);

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
                              // Branch on care status for paused; a null
                              // score means never scored, not paused.
                              if (_store.isPaused)
                                PausedHealthCard(plant: plant)
                              else if (!_store.isScored)
                                UnscoredHealthCard(
                                    onUpdate: () => _checkIn(plant))
                              else if (_store.band == HealthBand.thriving &&
                                  !_store.isStale)
                                FullHealthCard(store: _store)
                              else
                                AttentionHealthCard(store: _store),
                              if (_store.isStale) ...[
                                const SizedBox(height: AppSpacing.lg),
                                StaleNotice(onCheckIn: () => _checkIn(plant)),
                              ],
                              // Risk only arrives on the detail read and a
                              // check-in; a null here means not computed.
                              if (!_store.isPaused &&
                                  _store.risk != null &&
                                  _store.risk!.level != RiskLevel.low) ...[
                                const SizedBox(height: AppSpacing.lg),
                                RiskBanner(risk: _store.risk!),
                              ],
                              if (_store.isPaused) ...[
                                const SizedBox(height: AppSpacing.lg),
                                WhatStillWorksCard(photoCount: plant.photoCount),
                                const SizedBox(height: AppSpacing.lg),
                                const UnavailableTrendCard(),
                              ] else ...[
                                if (_store.careScore != null) ...[
                                  const SizedBox(height: AppSpacing.lg),
                                  CareScoreTile(careScore: _store.careScore!),
                                ],
                                const SizedBox(height: AppSpacing.lg),
                                TreatmentsSummaryCard(
                                  course: _store.openCourse,
                                  loaded: _store.coursesLoaded,
                                  onOpen: () => Navigator.of(context).pushNamed(
                                      AppRoutes.treatments,
                                      arguments: _store),
                                ),
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
                                156 + MediaQuery.viewPaddingOf(context).bottom,
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
                      onUpdate: () => _checkIn(plant),
                      onWater: _water,
                      onSkipWater: _skipWater,
                      onNote: _addNote,
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
    required this.onSkipWater,
    required this.onNote,
    required this.onResume,
  });

  final bool paused;
  final bool busy;
  final bool justWatered;
  final VoidCallback onUpdate;
  final VoidCallback onWater;
  final VoidCallback onSkipWater;
  final VoidCallback onNote;
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
      // Resume is only for a paused plant; a stale one comes back by being
      // checked in on, which is the first button below.
      child: paused
          ? AppButton.primary(
              label: 'Resume active care',
              loading: busy,
              onPressed: onResume,
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppButton(
                      label: 'Add a note',
                      style: AppButtonStyle.link,
                      expand: false,
                      fontSize: 14.5,
                      height: 36,
                      onPressed: busy ? null : onNote,
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    AppButton(
                      label: 'Skip watering',
                      style: AppButtonStyle.link,
                      expand: false,
                      fontSize: 14.5,
                      height: 36,
                      onPressed: busy ? null : onSkipWater,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
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
              ],
            ),
    );
  }
}
