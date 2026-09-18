import '../../enum.dart';

/// One reading on the health trend chart.
class HealthPoint {
  const HealthPoint({required this.date, required this.score});

  final DateTime date;
  final int score;
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
