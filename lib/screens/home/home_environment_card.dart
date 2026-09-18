import 'package:flutter/material.dart';

import '../../domain/models/plant_insight.dart';
import '../../domain/models/weather_data.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_surfaces.dart';
import '../../shared/components/headers.dart';
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
    if (loading || insight == null || weather == null) {
      return const Skeleton(height: 330, radius: AppRadius.card);
    }
    final w = weather!;
    return DarkCard(
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
                    const CaptionLabel('Environmental insight',
                        color: Color(0xFF9AA69C)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      insight!.title,
                      style: AppText.title28
                          .copyWith(fontSize: 23, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${w.temperatureC}°',
                      style: AppText.display40
                          .copyWith(fontSize: 39, color: AppColors.leaf)),
                  Text('Feels ${w.feelsLikeC}°',
                      style: AppText.body13.copyWith(
                          fontSize: 13, color: const Color(0xFF9AA69C))),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            insight!.body,
            style: AppText.body15.copyWith(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              _Stat(label: 'Humidity', value: '${w.humidity}%'),
              const SizedBox(width: AppSpacing.md),
              _Stat(label: 'UV index', value: w.uvLabel),
              const SizedBox(width: AppSpacing.md),
              _Stat(label: 'Rain', value: '${w.rainChance}%'),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton.primary(label: 'Open insights', onPressed: onOpen),
        ],
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
            horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppRadius.tile),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  style: AppText.body13
                      .copyWith(fontSize: 12.5, color: const Color(0xFF9AA69C))),
            ),
            const SizedBox(height: AppSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: AppText.heading17
                    .copyWith(fontSize: 16.5, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
