import '../../enum.dart';
import '../core/json.dart';

/// One reading on the health trend chart.
class HealthPoint {
  const HealthPoint({
    required this.date,
    required this.score,
    this.breakdown,
    this.provisional,
    this.careScore,
  });

  factory HealthPoint.fromJson(Map<String, dynamic> json) => HealthPoint(
        date: Json.day(json['date']),
        score: Json.integer(json['score']),
        breakdown:
            json['breakdown'] is Map ? Json.map(json['breakdown']) : null,
        provisional:
            json['provisional'] is bool ? json['provisional'] as bool : null,
        careScore: Json.intOrNull(json['care_score']),
      );

  /// The chartable points of a `history[]` payload. A day nothing scored has
  /// a `null` score; it is left off the line rather than drawn as a 0.
  static List<HealthPoint> listFromJson(Object? value) => Json.list(value)
      .where((p) => Json.intOrNull(p['score']) != null)
      .map(HealthPoint.fromJson)
      .toList();

  /// An owner-local date.
  final DateTime date;
  final int score;

  /// Every number the day's score was made of (`breakdown.version` says which
  /// shape). For a "why this number" sheet only — never a fixed model.
  final Map<String, dynamic>? breakdown;

  /// True when the photo was too poor to read, or the point is a carry-forward
  /// on a stale plant — the number is held lightly.
  final bool? provisional;

  /// The owner's adherence that day (0–100).
  final int? careScore;
}

enum RiskLevel { low, medium, high }

/// The coming week's risk, computed only on `GET /v1/plants/{id}` and on the
/// plant inside a finished check-in.
class Risk {
  const Risk({
    required this.level,
    required this.reasons,
    this.breakdown = const {},
  });

  static Risk? fromJson(Object? value) {
    if (value is! Map) return null;
    final json = Json.map(value);
    return Risk(
      level: Json.enumOf(json['level'], RiskLevel.values, RiskLevel.low),
      reasons: Json.strings(json['reasons']),
      breakdown: Json.map(json['breakdown']),
    );
  }

  final RiskLevel level;

  /// Short phrases meant to be printed as they are ("heatwave Tue to Thu").
  /// Empty exactly when [level] is low.
  final List<String> reasons;

  /// Every rule with its outcome. Not a display shape.
  final Map<String, dynamic> breakdown;
}

/// A single tile in the 2×2 metric grid on the plant dashboard.
class HealthMetric {
  const HealthMetric({
    required this.kind,
    required this.label,
    required this.value,
    required this.detail,
    required this.status,
  });

  final MetricKind kind;

  /// `Watering`, `Light`, `Environment`, `Condition`.
  final String label;

  /// The headline, e.g. `On track`.
  final String value;

  /// The supporting line, e.g. `Last watered 2 days ago`.
  final String detail;
  final MetricStatus status;
}

/// The written insight card under the trend chart.
class PlantInsight {
  const PlantInsight({
    required this.headline,
    required this.body,
    required this.tone,
  });

  final String headline;
  final String body;
  final MetricStatus tone;
}

/// A row in `Next actions`.
class NextAction {
  const NextAction({
    required this.title,
    required this.detail,
    required this.kind,
    this.highlighted = false,
  });

  final String title;
  final String detail;
  final MetricKind kind;

  /// Advisory rows sit on a lime-soft ground rather than white.
  final bool highlighted;
}
