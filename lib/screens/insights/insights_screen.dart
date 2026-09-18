import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../domain/models/plant_insight.dart';
import '../../enum.dart';
import '../../locator.dart';
import '../../shared/components/app_surfaces.dart';
import '../../shared/components/headers.dart';
import '../../shared/components/list_rows.dart';
import '../../shared/components/metric_card.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/trend_chart.dart';
import '../../stores/insights_store.dart';
import '../../theme.dart';
import '../shell/app_shell.dart';

/// `Insights` — the weather your plants are living in, what it means for them,
/// and how it has tracked with their health.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = locator<InsightsStore>();
    return ScreenBackground(
      glow: false,
      child: SafeArea(
        bottom: false,
        child: Observer(
          builder: (context) {
            if (store.isLoading && store.weather == null) {
              return ListView(
                padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xxl,
                    AppSpacing.gutter, navClearance(context)),
                children: const [
                  Skeleton(width: 190, height: 42),
                  SizedBox(height: AppSpacing.xl),
                  Skeleton(height: 250, radius: AppRadius.card),
                  SizedBox(height: AppSpacing.section),
                  Skeleton(height: 120, radius: AppRadius.card),
                  SizedBox(height: AppSpacing.md),
                  Skeleton(height: 120, radius: AppRadius.card),
                ],
              );
            }

            final weather = store.weather;
            if (weather == null) {
              return Center(
                child: Text(store.errorMessage ?? 'No readings yet',
                    style: AppText.body15),
              );
            }

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xxl,
                  AppSpacing.gutter, navClearance(context)),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Text('Insights', style: AppText.display40),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: 12),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.pillR,
                        boxShadow: AppShadows.raised,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const PgIcon(PgIcons.pin,
                              size: 19, color: AppColors.ink),
                          const SizedBox(width: AppSpacing.sm),
                          Text(weather.city,
                              style: AppText.heading17.copyWith(fontSize: 15)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Understand what your plants need',
                    style: AppText.body15.copyWith(fontSize: 16)),
                const SizedBox(height: AppSpacing.xl),
                DarkCard(
                  glow: const Color(0xFFF1B33C),
                  glowAlignment: const Alignment(0.72, -0.5),
                  glowOpacity: 0.34,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CaptionLabel('Right now',
                                    color: Color(0xFF9AA69C)),
                                const SizedBox(height: AppSpacing.md),
                                Text('${weather.temperatureC}°',
                                    style: AppText.display40.copyWith(
                                        fontSize: 52, color: Colors.white)),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  '${weather.condition} · feels '
                                  '${weather.feelsLikeC}°',
                                  style: AppText.body15.copyWith(
                                    fontSize: 16,
                                    color:
                                        Colors.white.withValues(alpha: 0.82),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PgIcon(PgIcons.sun,
                              size: 54, color: AppColors.leaf),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          _WeatherStat(
                              icon: PgIcons.droplet,
                              iconColor: AppColors.water,
                              value: '${weather.humidity}%',
                              label: 'Humidity'),
                          const SizedBox(width: AppSpacing.sm),
                          _WeatherStat(
                              icon: PgIcons.cloudRain,
                              iconColor: AppColors.water,
                              value: '${weather.rainChance}%',
                              label: 'Rain'),
                          const SizedBox(width: AppSpacing.sm),
                          _WeatherStat(
                              icon: PgIcons.sunLow,
                              iconColor: AppColors.caution,
                              value: '${weather.uvIndex}',
                              label: 'UV index'),
                          const SizedBox(width: AppSpacing.sm),
                          _WeatherStat(
                              icon: PgIcons.wind,
                              iconColor: AppColors.leaf,
                              value: '${weather.windKph} km/h',
                              label: 'Wind'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.section),
                SectionHeader(
                  title: "Today's insights",
                  trailing: '${store.newInsightCount} new',
                ),
                const SizedBox(height: AppSpacing.lg),
                for (var i = 0; i < store.insights.length; i++) ...[
                  Entrance(
                    index: i,
                    child: _InsightRow(insight: store.insights[i]),
                  ),
                  if (i != store.insights.length - 1)
                    const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(height: AppSpacing.section),
                const SectionHeader(title: 'Environmental history'),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.cardPadding,
                      AppSpacing.cardPadding,
                      AppSpacing.cardPadding,
                      AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          _LegendKey(
                              color: AppColors.caution, label: 'Temperature'),
                          SizedBox(width: AppSpacing.xl),
                          _LegendKey(
                              color: AppColors.water, label: 'Humidity'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      DualSeriesChart(
                        primary: store.environmentHistory
                            .map((e) => e.temperatureC)
                            .toList(),
                        secondary: store.environmentHistory
                            .map((e) => e.humidity)
                            .toList(),
                        labels: store.environmentHistory
                            .map((e) => '${e.day}')
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (store.correlation != null)
                  _CorrelationCard(correlation: store.correlation!),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WeatherStat extends StatelessWidget {
  const _WeatherStat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final PgIcons icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppRadius.tile),
        ),
        child: Column(
          children: [
            PgIcon(icon, size: 21, color: iconColor),
            const SizedBox(height: AppSpacing.md),
            FittedBox(
              child: Text(value,
                  style: AppText.heading17
                      .copyWith(fontSize: 16, color: Colors.white)),
            ),
            const SizedBox(height: 2),
            FittedBox(
              child: Text(label,
                  style: AppText.body13.copyWith(
                      fontSize: 12, color: const Color(0xFF9AA69C))),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight});

  final EnvironmentalInsight insight;

  @override
  Widget build(BuildContext context) {
    final (icon, tone) = switch (insight.kind) {
      InsightKind.heat => (PgIcons.thermometer, MetricStatus.watch),
      InsightKind.light => (PgIcons.moon, MetricStatus.neutral),
      InsightKind.rain => (PgIcons.cloudRain, MetricStatus.neutral),
      InsightKind.humidity => (PgIcons.dropletDouble, MetricStatus.neutral),
    };
    return TileRow(
      icon: icon,
      title: insight.title,
      detail: insight.body,
      tone: tone,
      iconBackground: insight.kind == InsightKind.rain
          ? AppColors.waterTint
          : null,
      iconForeground: insight.kind == InsightKind.rain
          ? AppColors.waterDeep
          : null,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
    );
  }
}

class _LegendKey extends StatelessWidget {
  const _LegendKey({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 4,
          decoration:
              BoxDecoration(color: color, borderRadius: AppRadius.pillR),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppText.body15Ink.copyWith(fontSize: 15)),
      ],
    );
  }
}

class _CorrelationCard extends StatelessWidget {
  const _CorrelationCard({required this.correlation});

  final HealthCorrelation correlation;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: AppColors.leafSoft,
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CaptionLabel('Health correlation', color: Color(0xFF4C6117)),
          const SizedBox(height: AppSpacing.md),
          Text(correlation.headline,
              style: AppText.title28.copyWith(fontSize: 23)),
          const SizedBox(height: AppSpacing.md),
          Text(correlation.body,
              style: AppText.body15
                  .copyWith(fontSize: 15, color: const Color(0xFF3F5015))),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: _CorrelationStat(
                    label: 'Humid weeks',
                    value: correlation.humidWeeksScore),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _CorrelationStat(
                    label: 'Dry weeks', value: correlation.dryWeeksScore),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CorrelationStat extends StatelessWidget {
  const _CorrelationStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.body13.copyWith(fontSize: 13)),
          const SizedBox(height: AppSpacing.sm),
          Text('$value', style: AppText.metric.copyWith(fontSize: 31.5)),
        ],
      ),
    );
  }
}
