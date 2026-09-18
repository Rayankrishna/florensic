import '../../enum.dart';
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
  });

  final String id;
  final PlantSpecies species;

  /// Display name — usually the species' common name.
  final String nickname;
  final String room;
  final bool indoor;
  final DateTime addedOn;

  /// `null` while care is paused: the score stops rather than decays.
  final int? healthScore;
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

  String get latinName => species.latinName;
  HealthBand get band => HealthBandX.fromScore(healthScore);
  bool get paused => careStatus == CareStatus.paused;

  DateTime get _today {
    final n = AppClock.now();
    return DateTime(n.year, n.month, n.day);
  }

  int get daysUntilWatering =>
      DateTime(schedule.nextWatering.year, schedule.nextWatering.month,
              schedule.nextWatering.day)
          .difference(_today)
          .inDays;

  int get daysSinceWatered => _today
      .difference(DateTime(schedule.lastWatered.year, schedule.lastWatered.month,
          schedule.lastWatered.day))
      .inDays;

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
      paused || waterDue || conditionDue || leafDropReported;

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
    int? healthScore,
    bool clearHealthScore = false,
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
  }) {
    return Plant(
      id: id,
      species: species,
      nickname: nickname,
      room: room,
      indoor: indoor,
      addedOn: addedOn,
      healthScore: clearHealthScore ? null : (healthScore ?? this.healthScore),
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
