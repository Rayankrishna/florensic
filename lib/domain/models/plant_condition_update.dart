import '../../enum.dart';
import '../core/json.dart';

/// A logged condition check-in: a photo plus what the keeper noticed.
class ConditionUpdate {
  const ConditionUpdate({
    required this.id,
    required this.plantId,
    required this.takenAt,
    required this.verdict,
    required this.observations,
    required this.note,
    this.scoreDelta,
    this.modelVerdict,
    this.verdictDisagreement = false,
    this.scoreBefore,
    this.scoreAfter,
    this.alpha,
    this.provisional,
    this.photoQuality,
    this.qualityIssue,
    this.newGrowth = false,
    this.flowering = false,
  });

  /// Built from `checkin.update` on a finished analysis job (§3.4).
  /// [scoreDelta] is `checkin.score_delta`, which sits beside `update`.
  factory ConditionUpdate.fromJson(
    Map<String, dynamic> json, {
    int? scoreDelta,
  }) {
    ConditionVerdict verdict(Object? value) => Json.enumOf(
          value,
          ConditionVerdict.values,
          ConditionVerdict.healthy,
          aliases: const {
            'healthy': ConditionVerdict.healthy,
            'concerns': ConditionVerdict.concerns,
            'needs_attention': ConditionVerdict.needsAttention,
          },
        );
    return ConditionUpdate(
      id: Json.str(json['id']),
      plantId: Json.str(json['plant_id']),
      takenAt: Json.date(json['created_at']),
      verdict: verdict(json['user_verdict']),
      observations: Json.strings(json['observations']),
      note: Json.str(json['note']),
      scoreDelta: scoreDelta ?? Json.intOrNull(json['score_delta']),
      modelVerdict: json['model_verdict'] == null
          ? null
          : verdict(json['model_verdict']),
      verdictDisagreement: Json.boolean(json['verdict_disagreement']),
      scoreBefore: Json.intOrNull(json['score_before']),
      scoreAfter: Json.intOrNull(json['score_after']),
      alpha: Json.doubleOrNull(json['alpha']),
      provisional:
          json['provisional'] is bool ? json['provisional'] as bool : null,
      photoQuality: Json.doubleOrNull(json['photo_quality']),
      qualityIssue: json['quality_issue'] is String
          ? json['quality_issue'] as String
          : null,
      newGrowth: Json.boolean(json['new_growth']),
      flowering: Json.boolean(json['flowering']),
    );
  }

  final String id;
  final String plantId;
  final DateTime takenAt;
  final ConditionVerdict verdict;

  /// What the model made of the photo, when it ran.
  final ConditionVerdict? modelVerdict;

  /// True when the keeper's verdict differed from the model's by more than
  /// one band, so the keeper's verdict was not counted toward the score.
  final bool verdictDisagreement;

  /// `scoreBefore` is null on a plant's first scored check-in; both are null
  /// on one the scorer never scored.
  final int? scoreBefore;
  final int? scoreAfter;

  /// 0–1: how much this photo was believed.
  final double? alpha;

  /// True when the photo was too poor to read, so the number is held
  /// lightly. [photoQuality] and [qualityIssue] say why.
  final bool? provisional;

  /// 0–1, how readable the photo was.
  final double? photoQuality;
  final String? qualityIssue;
  final bool newGrowth;
  final bool flowering;

  /// Chips the keeper selected, e.g. `Yellowing leaves`.
  final List<String> observations;
  final String note;

  /// How much this update moved the health score; null when there was no
  /// previous score to move from.
  final int? scoreDelta;

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
