import '../../enum.dart';
import '../core/json.dart';
import 'plant_care_schedule.dart';
import 'plant_condition_update.dart';
import 'plant_health.dart';
import 'plant_species.dart';
import '../../utils/app_clock.dart';

/// A plant in the keeper's collection.
///
/// Immutable; every mutation returns a copy so MobX observables swap the
/// whole object and rebuilds stay predictable.
class Plant {
  const Plant({
    required this.id,
    required this.species,
    required this.nickname,
    required this.room,
    required this.indoor,
    required this.addedOn,
    required this.healthScore,
    required this.healthBand,
    required this.careStatus,
    required this.schedule,
    required this.history,
    required this.updates,
    required this.careHistory,
    required this.photoCount,
    required this.streakWeeks,
    required this.lightStatus,
    required this.lightDetail,
    this.leafDropReported = false,
    this.needsAttentionFlag,
    this.careScore,
    this.risk,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    final species = PlantSpecies.fromJson(Json.map(json['species']));
    final score = Json.intOrNull(json['health_score']);
    final status = Json.enumOf(
      json['care_status'],
      CareStatus.values,
      CareStatus.active,
    );
    return Plant(
      id: Json.str(json['id']),
      species: species,
      nickname: Json.str(json['nickname'], species.commonName),
      room: Json.str(json['room'], 'Unassigned'),
      indoor: Json.boolean(json['indoor'], true),
      addedOn: Json.date(json['added_on']),
      healthScore: score,
      // The server's band wins, and is null for a paused or unscored plant.
      healthBand: json.containsKey('health_band')
          ? _bandOf(json['health_band'])
          : (status == CareStatus.paused ? null : HealthBandX.fromScore(score)),
      careStatus: status,
      schedule: CareSchedule.fromJson(Json.map(json['schedule'])),
      history: HealthPoint.listFromJson(json['history']),
      // Updates are not embedded; the detail screen fetches them separately.
      updates: const [],
      careHistory:
          Json.list(json['care_history']).map(CareEvent.fromJson).toList(),
      photoCount: Json.integer(json['photo_count']),
      streakWeeks: Json.integer(json['streak_weeks']),
      lightStatus: Json.status(json['light_status'], MetricStatus.neutral),
      lightDetail: Json.str(json['light_detail']),
      leafDropReported: Json.boolean(json['leaf_drop_reported']),
      needsAttentionFlag: json['needs_attention'] is bool
          ? json['needs_attention'] as bool
          : null,
      careScore: Json.intOrNull(json['care_score']),
      risk: Risk.fromJson(json['risk']),
    );
  }

  static HealthBand? _bandOf(Object? value) => switch (value) {
        'thriving' => HealthBand.thriving,
        'watch' => HealthBand.watch,
        'critical' => HealthBand.critical,
        _ => null,
      };

  final String id;
  final PlantSpecies species;

  /// Display name — usually the species' common name.
  final String nickname;
  final String room;
  final bool indoor;
  final DateTime addedOn;

  /// What the photographs showed. `null` means nothing has scored the plant
  /// yet — it does not mean paused; a paused plant keeps its last number.
  final int? healthScore;

  /// `null` when there is no band to show: never scored, or paused.
  final HealthBand? healthBand;
  final CareStatus careStatus;
  final CareSchedule schedule;

  /// Ordered oldest → newest.
  final List<HealthPoint> history;
  final List<ConditionUpdate> updates;
  final List<CareEvent> careHistory;
  final int photoCount;
  final int streakWeeks;
  final MetricStatus lightStatus;
  final String lightDetail;
  final bool leafDropReported;

  /// The server's own verdict. When present it wins, so the app and the
  /// backend never disagree about what needs attention (§5).
  final bool? needsAttentionFlag;

  /// The owner's side: how much of the care due over 30 days was given on
  /// time. 100 when nothing was due.
  final int? careScore;

  /// Only the detail read and a finished check-in compute this; everywhere
  /// else it arrives as `null`, meaning "not computed here".
  final Risk? risk;

  String get latinName => species.latinName;
  HealthBand? get band => healthBand;
  bool get paused => careStatus == CareStatus.paused;

  /// One check-in window missed: still under care, just not seen lately.
  bool get stale => careStatus == CareStatus.stale;
  bool get scored => healthScore != null;

  /// Keeps a risk computed by an earlier read when this copy came back from a
  /// write that does not compute one.
  Plant keepingRiskOf(Plant? previous) =>
      risk == null && previous?.risk != null && previous!.id == id
          ? copyWith(risk: previous.risk)
          : this;

  DateTime get _today {
    final n = AppClock.now();
    return DateTime(n.year, n.month, n.day);
  }

  int get daysUntilWatering =>
      DateTime(schedule.nextWatering.year, schedule.nextWatering.month,
              schedule.nextWatering.day)
          .difference(_today)
          .inDays;

  /// Null when no watering has been logged yet.
  int? get daysSinceWatered {
    final last = schedule.lastWatered;
    if (last == null) return null;
    return _today.difference(DateTime(last.year, last.month, last.day)).inDays;
  }

  DateTime? get lastConditionUpdate =>
      updates.isEmpty ? null : updates.last.takenAt;

  int? get daysSinceCondition {
    final last = lastConditionUpdate;
    if (last == null) return null;
    return _today.difference(DateTime(last.year, last.month, last.day)).inDays;
  }

  /// A condition update is due once the check-in window has opened.
  bool get conditionDue =>
      !paused && !_today.isBefore(_stripTime(schedule.checkInWindowOpens));

  int get conditionOverdueDays => conditionDue
      ? _today.difference(_stripTime(schedule.checkInWindowOpens)).inDays
      : 0;

  bool get waterDue => daysUntilWatering <= 0;

  bool get needsAttention =>
      needsAttentionFlag ??
      (paused || stale || waterDue || conditionDue || leafDropReported);

  /// 7-day change in the health score, from [history].
  int get weeklyChange {
    if (history.length < 2 || healthScore == null) return 0;
    final cutoff = _today.subtract(const Duration(days: 7));
    final earlier = history.firstWhere(
      (p) => !p.date.isBefore(cutoff),
      orElse: () => history.first,
    );
    return healthScore! - earlier.score;
  }

  /// The coloured status line under the name on a collection card.
  PlantStatusLine get statusLine {
    if (paused) {
      return const PlantStatusLine('Care status paused', MetricStatus.neutral);
    }
    if (leafDropReported) {
      return const PlantStatusLine('Leaf drop reported', MetricStatus.bad);
    }
    if (stale) {
      return const PlantStatusLine(
          'Not seen lately · check in', MetricStatus.watch);
    }
    if (conditionDue) {
      return PlantStatusLine(
        conditionOverdueDays > 0
            ? 'Update overdue by ${conditionOverdueDays}d'
            : 'Update due today',
        MetricStatus.watch,
      );
    }
    if (waterDue) {
      return const PlantStatusLine('Water today', MetricStatus.good,
          isWater: true);
    }
    return PlantStatusLine(
      'Healthy · water in ${daysUntilWatering}d',
      MetricStatus.good,
    );
  }

  static DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);

  Plant copyWith({
    CareStatus? careStatus,
    CareSchedule? schedule,
    List<HealthPoint>? history,
    List<ConditionUpdate>? updates,
    List<CareEvent>? careHistory,
    int? photoCount,
    int? streakWeeks,
    MetricStatus? lightStatus,
    String? lightDetail,
    bool? leafDropReported,
    bool? needsAttentionFlag,
    Risk? risk,
  }) {
    return Plant(
      id: id,
      species: species,
      nickname: nickname,
      room: room,
      indoor: indoor,
      addedOn: addedOn,
      healthScore: healthScore,
      healthBand: healthBand,
      careStatus: careStatus ?? this.careStatus,
      schedule: schedule ?? this.schedule,
      history: history ?? this.history,
      updates: updates ?? this.updates,
      careHistory: careHistory ?? this.careHistory,
      photoCount: photoCount ?? this.photoCount,
      streakWeeks: streakWeeks ?? this.streakWeeks,
      lightStatus: lightStatus ?? this.lightStatus,
      lightDetail: lightDetail ?? this.lightDetail,
      leafDropReported: leafDropReported ?? this.leafDropReported,
      needsAttentionFlag: needsAttentionFlag ?? this.needsAttentionFlag,
      careScore: careScore,
      risk: risk ?? this.risk,
    );
  }
}

/// Status text plus the tone it is painted in.
class PlantStatusLine {
  const PlantStatusLine(this.label, this.status, {this.isWater = false});

  final String label;
  final MetricStatus status;

  /// Water-blue rather than the usual green for "good".
  final bool isWater;
}
