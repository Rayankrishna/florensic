import 'package:mobx/mobx.dart';

import '../domain/models/plant.dart';
import '../domain/models/plant_health.dart';
import '../domain/models/treatment.dart';
import '../domain/repositories/plant_repository.dart';
import '../enum.dart';
import '../interceptors/api_interceptor.dart';
import '../utils/app_log.dart';
import '../utils/date_format.dart';
import 'plant_collection_store.dart';
import '../utils/app_clock.dart';

part 'plant_detail_store.g.dart';

class PlantDetailStore = _PlantDetailStore with _$PlantDetailStore;

/// Everything the plant health dashboard and care schedule render.
///
/// The metric copy here is derived from the plant's own record — watering
/// dates, light position, the most recent condition update and the ambient
/// reading. It is descriptive, not diagnostic.
abstract class _PlantDetailStore with Store {
  _PlantDetailStore(this._repository, this._collection);

  final PlantRepository _repository;
  final PlantCollectionStore _collection;

  @observable
  Plant? plant;

  @observable
  LoadState state = LoadState.idle;

  @observable
  String? errorMessage;

  @observable
  TrendRange range = TrendRange.week;

  @observable
  bool isBusy = false;

  /// Set briefly after `Mark as watered` so the button can confirm.
  @observable
  bool justWatered = false;

  @computed
  bool get isLoading => state == LoadState.loading;

  @computed
  int? get healthScore => plant?.healthScore;

  /// Null when there is no band to show: never scored, or paused.
  @computed
  HealthBand? get band => plant?.band;

  @computed
  CareStatus get careStatus => plant?.careStatus ?? CareStatus.active;

  @computed
  bool get isPaused => plant?.paused ?? false;

  /// One missed check-in window: still under care, just not seen lately.
  @computed
  bool get isStale => plant?.stale ?? false;

  @computed
  bool get isScored => plant?.scored ?? false;

  @computed
  int? get careScore => plant?.careScore;

  @computed
  Risk? get risk => plant?.risk;

  @computed
  String get bandLabel => switch (band) {
        HealthBand.thriving => 'Looking good',
        HealthBand.watch => 'Needs attention',
        HealthBand.critical => 'Needs attention',
        null => isPaused ? 'Care status paused' : 'Not scored yet',
      };

  /// Every treatment plan the plant has had, newest first — one plan at a
  /// time, problems worst first, steps in one order. Refetched after each
  /// check-in because every check-in judges every open problem.
  @observable
  ObservableList<Course> courses = ObservableList<Course>();

  @observable
  bool coursesLoaded = false;

  /// The plan in progress, if any.
  @computed
  Course? get openCourse {
    for (final c in courses) {
      if (c.isOpen) return c;
    }
    return null;
  }

  @computed
  int get weeklyChange => plant?.weeklyChange ?? 0;

  @computed
  int get streakWeeks => plant?.streakWeeks ?? 0;

  @computed
  int get updateCount => plant?.updates.length ?? 0;

  // ── Metric grid ──────────────────────────────────────────────────────────

  @computed
  HealthMetric get wateringMetric {
    final p = plant;
    if (p == null) {
      return const HealthMetric(
        kind: MetricKind.watering,
        label: 'Watering',
        value: '—',
        detail: '',
        status: MetricStatus.neutral,
      );
    }
    final days = p.daysUntilWatering;
    if (days < 0) {
      return HealthMetric(
        kind: MetricKind.watering,
        label: 'Watering',
        value: 'Overdue',
        detail: '${-days} day${days == -1 ? '' : 's'} late',
        status: MetricStatus.bad,
      );
    }
    if (days == 0) {
      return const HealthMetric(
        kind: MetricKind.watering,
        label: 'Watering',
        value: 'Due today',
        detail: 'Water it when you can',
        status: MetricStatus.watch,
      );
    }
    return HealthMetric(
      kind: MetricKind.watering,
      label: 'Watering',
      value: 'On track',
      detail: p.daysSinceWatered == null
          ? 'No watering logged yet'
          : 'Last watered ${AppDate.relativeDays(p.daysSinceWatered!)}',
      status: MetricStatus.good,
    );
  }

  @computed
  HealthMetric get lightMetric {
    final p = plant;
    if (p == null) {
      return const HealthMetric(
        kind: MetricKind.light,
        label: 'Light',
        value: '—',
        detail: '',
        status: MetricStatus.neutral,
      );
    }
    return HealthMetric(
      kind: MetricKind.light,
      label: 'Light',
      value: switch (p.lightStatus) {
        MetricStatus.good => 'Optimal',
        MetricStatus.watch => 'Too direct',
        MetricStatus.bad => 'Too little',
        MetricStatus.neutral => 'Unmeasured',
      },
      detail: p.lightDetail,
      status: p.lightStatus,
    );
  }

  /// Ambient conditions. Populated from the insights store when available.
  @observable
  String environmentDetail = '28°C · 74% humidity';

  @observable
  MetricStatus environmentStatus = MetricStatus.good;

  @computed
  HealthMetric get environmentMetric => HealthMetric(
        kind: MetricKind.environment,
        label: 'Environment',
        value: switch (environmentStatus) {
          MetricStatus.good => 'Favourable',
          MetricStatus.watch => 'Warm',
          MetricStatus.bad => 'Stressful',
          MetricStatus.neutral => 'Unknown',
        },
        detail: environmentDetail,
        status: environmentStatus,
      );

  @computed
  HealthMetric get conditionMetric {
    final p = plant;
    final days = p?.daysSinceCondition;
    if (p == null || days == null) {
      return const HealthMetric(
        kind: MetricKind.condition,
        label: 'Condition',
        value: 'No updates',
        detail: 'Add your first photo',
        status: MetricStatus.neutral,
      );
    }
    final last = p.updates.last;
    final status = switch (last.verdict) {
      ConditionVerdict.healthy =>
        p.conditionDue ? MetricStatus.watch : MetricStatus.good,
      ConditionVerdict.concerns => MetricStatus.watch,
      ConditionVerdict.needsAttention => MetricStatus.bad,
    };
    return HealthMetric(
      kind: MetricKind.condition,
      label: 'Condition',
      value: switch (last.verdict) {
        ConditionVerdict.healthy => 'Stable',
        ConditionVerdict.concerns => 'Watch',
        ConditionVerdict.needsAttention => 'Declining',
      },
      detail: 'Updated ${AppDate.relativeDays(days)}',
      status: status,
    );
  }

  @computed
  List<HealthMetric> get metrics =>
      [wateringMetric, lightMetric, environmentMetric, conditionMetric];

  // ── Trend ────────────────────────────────────────────────────────────────

  @computed
  List<HealthPoint> get trendSeries {
    final history = plant?.history ?? const [];
    if (history.isEmpty) return const [];
    final days = range.days;
    final cutoff = AppClock.now().subtract(Duration(days: days - 1));
    final window =
        history.where((p) => !p.date.isBefore(_stripTime(cutoff))).toList();
    if (window.length <= 2) return history.length <= 2 ? history : window;
    if (range == TrendRange.week) return window;
    // Down-sample longer ranges so the line stays readable.
    const target = 14;
    if (window.length <= target) return window;
    final step = window.length / target;
    return List.generate(
      target,
      (i) => window[(i * step).floor().clamp(0, window.length - 1)],
    )..add(window.last);
  }

  @computed
  List<String> get trendLabels {
    final series = trendSeries;
    if (series.isEmpty) return const [];
    if (range == TrendRange.week) {
      return series.map((p) => AppDate.weekdayShort(p.date)).toList();
    }
    return [
      AppDate.dayMonth(series.first.date),
      if (series.length > 2) AppDate.dayMonth(series[series.length ~/ 2].date),
      AppDate.dayMonth(series.last.date),
    ];
  }

  @computed
  bool get hasTrendData => trendSeries.length >= 2;

  // ── Narrative ────────────────────────────────────────────────────────────

  @computed
  PlantInsight get latestInsight {
    final p = plant;
    if (p == null || p.paused) {
      return const PlantInsight(
        headline: 'Plant health data unavailable',
        body: 'Trends need at least one update in the last 30 days. The chart '
            'returns as soon as you add one.',
        tone: MetricStatus.neutral,
      );
    }
    if (!p.scored) {
      return const PlantInsight(
        headline: 'Nothing has scored this plant yet.',
        body: 'Add a condition photo and its health score starts from what '
            'the picture shows.',
        tone: MetricStatus.neutral,
      );
    }
    if (p.stale) {
      return const PlantInsight(
        headline: 'We have not seen this one lately.',
        body: 'Its last check-in window closed without a photo. The score '
            'stands; a new check-in brings it back up to date.',
        tone: MetricStatus.neutral,
      );
    }
    if (band == HealthBand.thriving) {
      return const PlantInsight(
        headline: 'Your plant is doing well.',
        body: 'Recent conditions are within its preferred range. New growth in '
            'the last two updates suggests the light position is working.',
        tone: MetricStatus.good,
      );
    }
    return PlantInsight(
      headline: 'Your plant may need attention.',
      body: 'Recent condition updates show possible stress. Check moisture and '
          'light exposure — ${p.nickname.toLowerCase()}s react quickly after a '
          'change of spot.',
      tone: MetricStatus.bad,
    );
  }

  @computed
  String get attentionHeadline {
    if (isStale) return 'Not seen lately';
    final change = weeklyChange;
    if (change < 0) return 'Down ${-change} this week';
    if (change > 0) return 'Up $change this week';
    return 'Steady this week';
  }

  @computed
  String get attentionBody {
    final p = plant;
    if (p == null) return '';
    final reasons = <String>[];
    if (p.stale) reasons.add('a missed check-in window');
    if (p.leafDropReported) reasons.add('two reports of leaf drop');
    if (p.daysUntilWatering < 0) reasons.add('a missed watering');
    if (p.conditionDue) reasons.add('an overdue check-in');
    if (reasons.isEmpty) return 'Based on your most recent condition updates.';
    return 'Driven by ${_joinNaturally(reasons)}.';
  }

  @computed
  List<NextAction> get nextActions {
    final p = plant;
    if (p == null) return const [];
    final actions = <NextAction>[];
    final days = p.daysUntilWatering;
    if (days < 0) {
      actions.add(NextAction(
        title: 'Water now, then log it',
        detail: '${-days} day${days == -1 ? '' : 's'} past its schedule',
        kind: MetricKind.watering,
      ));
    } else {
      actions.add(NextAction(
        title: 'Watering due',
        detail: days == 0
            ? 'Today · ${AppDate.dayMonth(p.schedule.nextWatering)}'
            : 'In $days days · ${AppDate.weekdayDayMonth(p.schedule.nextWatering)}',
        kind: MetricKind.watering,
      ));
    }
    actions.add(NextAction(
      title: 'Condition update due',
      detail: p.conditionDue
          ? 'Today · keeps care status active'
          : 'Opens ${AppDate.weekdayDayMonth(p.schedule.checkInWindowOpens)}',
      kind: MetricKind.condition,
    ));
    if (p.lightStatus == MetricStatus.watch) {
      actions.add(const NextAction(
        title: 'Move a metre back from the window',
        detail: 'Direct afternoon sun may scorch the leaves.',
        kind: MetricKind.light,
        highlighted: true,
      ));
    } else {
      actions.add(const NextAction(
        title: 'Move 30cm from the window',
        detail: 'UV index 7 today — direct afternoon sun may scorch.',
        kind: MetricKind.light,
        highlighted: true,
      ));
    }
    return actions;
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  @action
  void setRange(TrendRange value) => range = value;

  @action
  void setEnvironment(String detail, MetricStatus status) {
    environmentDetail = detail;
    environmentStatus = status;
  }

  @action
  Future<void> loadPlantDetails(String plantId) async {
    state = LoadState.loading;
    errorMessage = null;
    final known = _collection.plantById(plantId);
    if (known != null) {
      plant = known;
      state = LoadState.ready;
      return;
    }
    try {
      await _collection.loadPlants();
    } catch (e, stack) {
      AppLog.e('loading plant $plantId failed',
          name: 'plants', error: e, stackTrace: stack);
      runInAction(() {
        errorMessage = e is ApiException ? e.message : e.toString();
        state = LoadState.error;
      });
      return;
    }

    final found = _collection.plantById(plantId);
    runInAction(() {
      plant = found;
      state = found == null ? LoadState.error : LoadState.ready;
      if (found == null) {
        errorMessage = 'That plant is no longer in your collection.';
      }
    });
  }

  @action
  void attach(Plant value) {
    plant = value;
    state = LoadState.ready;
    courses.clear();
    coursesLoaded = false;
  }

  @action
  Future<void> loadCourses() async {
    final p = plant;
    if (p == null) return;
    try {
      final list = await _repository.loadCourses(p.id);
      runInAction(() {
        courses = ObservableList<Course>.of(list);
        coursesLoaded = true;
      });
    } catch (e, stack) {
      AppLog.e('loading treatment plans failed',
          name: 'plants', error: e, stackTrace: stack);
      runInAction(() => coursesLoaded = true);
    }
  }

  /// Stops one problem's course on the plan.
  @action
  Future<bool> abandonProblem(CourseProblem problem, AbandonReason reason,
          {String? note}) =>
      _stop(
        'treatment ${problem.problem}',
        () => _repository.abandonTreatment(problem.treatmentId, reason,
            note: note),
      );

  /// Stops every open problem on the plan at once.
  @action
  Future<bool> abandonCourse(Course course, AbandonReason reason,
          {String? note}) =>
      _stop(
        'plan ${course.id}',
        () => _repository.abandonCourse(course.id, reason, note: note),
      );

  Future<bool> _stop(String what, Future<void> Function() call) async {
    if (isBusy) return false;
    runInAction(() => isBusy = true);
    try {
      await call();
      AppLog.i('stopped $what', name: 'plants');
      // Its steps have left today's list and the check-in cadence went back.
      await _collection.refreshTodaysCare();
      await loadCourses();
      return true;
    } catch (e, stack) {
      AppLog.e('stopping $what failed',
          name: 'plants', error: e, stackTrace: stack);
      runInAction(
          () => errorMessage = e is ApiException ? e.message : e.toString());
      // It may already be closed; show what the server has.
      await loadCourses();
      return false;
    } finally {
      runInAction(() => isBusy = false);
    }
  }

  @action
  Future<bool> skipWatering(WateringSkipReason reason) async {
    final p = plant;
    if (p == null || isBusy) return false;
    isBusy = true;
    try {
      final updated = await _collection.skipWatering(p.id, reason);
      if (updated != null) {
        runInAction(() => plant = updated.keepingRiskOf(p));
      }
      return updated != null;
    } finally {
      runInAction(() => isBusy = false);
    }
  }

  @action
  Future<bool> addNote(List<NoteChip> chips, {String? text}) async {
    final p = plant;
    if (p == null || isBusy) return false;
    isBusy = true;
    try {
      final updated = await _collection.addNote(p.id, chips, text: text);
      if (updated != null) {
        runInAction(() => plant = updated.keepingRiskOf(p));
      }
      return updated != null;
    } finally {
      runInAction(() => isBusy = false);
    }
  }

  @action
  Future<void> markAsWatered() async {
    final p = plant;
    if (p == null || isBusy) return;
    isBusy = true;
    try {
      final updated = await _collection.markAsWatered(p.id);
      if (updated != null) {
        runInAction(() {
          // The score does not move on a watering, and the response does not
          // compute risk, so the one on screen stays.
          plant = updated.keepingRiskOf(p);
          justWatered = true;
        });
        Future<void>.delayed(const Duration(seconds: 2), () {
          runInAction(() => justWatered = false);
        });
      }
    } finally {
      runInAction(() => isBusy = false);
    }
  }

  /// Paused plants only — a stale plant comes back through a check-in, and
  /// the server answers `409 plant_not_paused` to say so.
  @action
  Future<void> resumeActiveCare() async {
    final p = plant;
    if (p == null || isBusy || !p.paused) return;
    isBusy = true;
    try {
      final updated = await _repository.resumeActiveCare(p.id);
      AppLog.i('resumed care for ${updated.nickname}', name: 'plants');
      runInAction(() {
        plant = updated;
        _collection.replacePlant(updated);
      });
    } catch (e, stack) {
      AppLog.e('resuming care failed',
          name: 'plants', error: e, stackTrace: stack);
      runInAction(
          () => errorMessage = e is ApiException ? e.message : e.toString());
    } finally {
      runInAction(() => isBusy = false);
    }
  }

  @action
  Future<void> setReminder({bool? watering, bool? checkIn}) async {
    final p = plant;
    if (p == null) return;
    final updated =
        await _repository.setReminder(p.id, watering: watering, checkIn: checkIn);
    runInAction(() {
      plant = updated.keepingRiskOf(p);
      _collection.replacePlant(updated);
    });
  }

  /// Called by the condition-update flow once a new update is saved. The
  /// check-in judged every open problem and may have added one to the plan,
  /// so the plans are refetched.
  @action
  void applyUpdatedPlant(Plant updated) {
    plant = updated;
    _collection.replacePlant(updated);
    loadCourses();
  }

  static DateTime _stripTime(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _joinNaturally(List<String> parts) {
    if (parts.length == 1) return parts.first;
    return '${parts.sublist(0, parts.length - 1).join(', ')} and ${parts.last}';
  }
}
