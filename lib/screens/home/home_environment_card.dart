import 'package:flutter/material.dart';

import '../../domain/models/plant_insight.dart';
import '../../domain/models/weather_data.dart';
import '../../shared/components/app_surfaces.dart';
import '../../shared/components/headers.dart';
import '../../shared/components/pressable.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../shared/widgets/skeleton.dart';
import '../../theme.dart';

/// The ink environmental panel at the foot of the home dashboard.
class HomeEnvironmentCard extends StatelessWidget {
  const HomeEnvironmentCard({
    super.key,
    required this.insight,
    required this.weather,
    required this.loading,
    required this.onOpen,
  });

  final HomeEnvironmentInsight? insight;
  final WeatherData? weather;
  final bool loading;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Skeleton(height: 220, radius: AppRadius.card);
    }
    // No insight and not loading means the backend has nothing to say today.
    // A skeleton here would spin for ever, so the section simply goes away.
    if (insight == null) return const SizedBox.shrink();
    final w = weather;
    // The whole card opens Insights; a link line at the foot says so, in
    // place of the full-height button the panel used to carry.
    return Pressable(
      onTap: onOpen,
      semanticLabel: 'Open insights',
      child: DarkCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        glowAlignment: const Alignment(0.85, -0.9),
        glowRadius: 0.62,
        glowOpacity: 0.30,
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
                      const CaptionLabel(
                        'Environmental insight',
                        color: Color(0xFF9AA69C),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        insight!.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title28.copyWith(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                if (w != null) ...[
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${w.temperatureC}°',
                        style: AppText.display40.copyWith(
                          fontSize: 32,
                          color: AppColors.leaf,
                        ),
                      ),
                      Text(
                        'Feels ${w.feelsLikeC}°',
                        style: AppText.body13.copyWith(
                          fontSize: 12.5,
                          color: const Color(0xFF9AA69C),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              insight!.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.body15.copyWith(
                fontSize: 14.5,
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
            // The stat row needs a weather reading, which has no endpoint yet.
            if (w != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  _Stat(label: 'Humidity', value: '${w.humidity}%'),
                  const SizedBox(width: AppSpacing.md),
                  _Stat(label: 'UV index', value: w.uvLabel),
                  const SizedBox(width: AppSpacing.md),
                  _Stat(label: 'Rain', value: '${w.rainChance}%'),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Text(
                  'Open insights',
                  style: AppText.label13.copyWith(
                    fontSize: 14,
                    color: AppColors.leaf,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const PgIcon(PgIcons.chevronRight,
                    size: 16, color: AppColors.leaf),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppRadius.tile),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: AppText.body13.copyWith(
                  fontSize: 12.5,
                  color: const Color(0xFF9AA69C),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: AppText.heading17.copyWith(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
