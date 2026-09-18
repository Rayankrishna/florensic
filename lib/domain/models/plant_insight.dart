import '../../enum.dart';

/// A card in `Today's insights`.
class EnvironmentalInsight {
  const EnvironmentalInsight({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    this.isNew = true,
  });

  final String id;
  final String title;
  final String body;
  final InsightKind kind;
  final bool isNew;
}

enum InsightKind { heat, light, rain, humidity }

/// The `Health correlation` panel at the foot of Insights.
class HealthCorrelation {
  const HealthCorrelation({
    required this.headline,
    required this.body,
    required this.humidWeeksScore,
    required this.dryWeeksScore,
  });

  final String headline;
  final String body;
  final int humidWeeksScore;
  final int dryWeeksScore;
}

/// The dark environmental card on the home dashboard.
class HomeEnvironmentInsight {
  const HomeEnvironmentInsight({
    required this.title,
    required this.body,
    required this.tone,
  });

  final String title;
  final String body;
  final MetricStatus tone;
}
