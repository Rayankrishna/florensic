import '../../enum.dart';

/// A logged condition check-in: a photo plus what the keeper noticed.
class ConditionUpdate {
  const ConditionUpdate({
    required this.id,
    required this.plantId,
    required this.takenAt,
    required this.verdict,
    required this.observations,
    required this.note,
    required this.scoreDelta,
  });

  final String id;
  final String plantId;
  final DateTime takenAt;
  final ConditionVerdict verdict;

  /// Chips the keeper selected, e.g. `Yellowing leaves`.
  final List<String> observations;
  final String note;

  /// How much this update moved the health score.
  final int scoreDelta;

  /// Options offered on the details step.
  static const List<String> observationOptions = [
    'Yellowing leaves',
    'Drooping',
    'Dry soil',
    'Leaf damage',
    'Pests',
    'Slow growth',
    'Other',
  ];
}
