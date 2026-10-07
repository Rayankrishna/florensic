import '../../enum.dart';
import '../core/json.dart';

/// A card in `Today's insights`.
class EnvironmentalInsight {
  const EnvironmentalInsight({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    this.isNew = true,
  });

  factory EnvironmentalInsight.fromJson(
    Map<String, dynamic> json, {
    DateTime? today,
  }) {
    final day = Json.dateOrNull(json['day']);
    final now = today ?? DateTime.now();
    return EnvironmentalInsight(
      id: Json.str(json['id']),
      title: Json.str(json['headline']),
      body: Json.str(json['body']),
      kind: Json.enumOf(json['kind'], InsightKind.values, InsightKind.heat,
          aliases: const {
            'heat': InsightKind.heat,
            'low_humidity': InsightKind.humidity,
            'rain': InsightKind.rain,
            'low_light_season': InsightKind.light,
          }),
      isNew: day == null ||
          (day.year == now.year && day.month == now.month && day.day == now.day),
    );
  }

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

  /// `correlation` on the insights response; null until there is enough
  /// history, which keeps the screen's empty state honest.
  static HealthCorrelation? fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return null;
    final humid = Json.doubleOrNull(json['humid_mean'])?.round();
    final dry = Json.doubleOrNull(json['dry_mean'])?.round();
    if (humid == null || dry == null) return null;
    final delta = humid - dry;
    return HealthCorrelation(
      headline: delta > 0
          ? 'Humidity above 60% tracks with your best health scores.'
          : 'Humidity is not moving your scores much yet.',
      body: 'Across recent weeks of updates, your tropical plants score '
          '${delta.abs()} points ${delta >= 0 ? 'higher' : 'lower'} on humid '
          'weeks.',
      humidWeeksScore: humid,
      dryWeeksScore: dry,
    );
  }

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
