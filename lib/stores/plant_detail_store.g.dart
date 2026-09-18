// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plant_detail_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$PlantDetailStore on _PlantDetailStore, Store {
  Computed<bool>? _$isLoadingComputed;

  @override
  bool get isLoading => (_$isLoadingComputed ??= Computed<bool>(
    () => super.isLoading,
    name: '_PlantDetailStore.isLoading',
  )).value;
  Computed<int?>? _$healthScoreComputed;

  @override
  int? get healthScore => (_$healthScoreComputed ??= Computed<int?>(
    () => super.healthScore,
    name: '_PlantDetailStore.healthScore',
  )).value;
  Computed<HealthBand>? _$bandComputed;

  @override
  HealthBand get band => (_$bandComputed ??= Computed<HealthBand>(
    () => super.band,
    name: '_PlantDetailStore.band',
  )).value;
  Computed<CareStatus>? _$careStatusComputed;

  @override
  CareStatus get careStatus => (_$careStatusComputed ??= Computed<CareStatus>(
    () => super.careStatus,
    name: '_PlantDetailStore.careStatus',
  )).value;
  Computed<bool>? _$isPausedComputed;

  @override
  bool get isPaused => (_$isPausedComputed ??= Computed<bool>(
    () => super.isPaused,
    name: '_PlantDetailStore.isPaused',
  )).value;
  Computed<String>? _$bandLabelComputed;

  @override
  String get bandLabel => (_$bandLabelComputed ??= Computed<String>(
    () => super.bandLabel,
    name: '_PlantDetailStore.bandLabel',
  )).value;
  Computed<int>? _$weeklyChangeComputed;

  @override
  int get weeklyChange => (_$weeklyChangeComputed ??= Computed<int>(
    () => super.weeklyChange,
    name: '_PlantDetailStore.weeklyChange',
  )).value;
  Computed<int>? _$streakWeeksComputed;

  @override
  int get streakWeeks => (_$streakWeeksComputed ??= Computed<int>(
    () => super.streakWeeks,
    name: '_PlantDetailStore.streakWeeks',
  )).value;
  Computed<int>? _$updateCountComputed;

  @override
  int get updateCount => (_$updateCountComputed ??= Computed<int>(
    () => super.updateCount,
    name: '_PlantDetailStore.updateCount',
  )).value;
  Computed<HealthMetric>? _$wateringMetricComputed;

  @override
  HealthMetric get wateringMetric =>
      (_$wateringMetricComputed ??= Computed<HealthMetric>(
        () => super.wateringMetric,
        name: '_PlantDetailStore.wateringMetric',
      )).value;
  Computed<HealthMetric>? _$lightMetricComputed;

  @override
  HealthMetric get lightMetric =>
      (_$lightMetricComputed ??= Computed<HealthMetric>(
        () => super.lightMetric,
        name: '_PlantDetailStore.lightMetric',
      )).value;
  Computed<HealthMetric>? _$environmentMetricComputed;

  @override
  HealthMetric get environmentMetric =>
      (_$environmentMetricComputed ??= Computed<HealthMetric>(
        () => super.environmentMetric,
        name: '_PlantDetailStore.environmentMetric',
      )).value;
  Computed<HealthMetric>? _$conditionMetricComputed;

  @override
  HealthMetric get conditionMetric =>
      (_$conditionMetricComputed ??= Computed<HealthMetric>(
        () => super.conditionMetric,
        name: '_PlantDetailStore.conditionMetric',
      )).value;
  Computed<List<HealthMetric>>? _$metricsComputed;

  @override
  List<HealthMetric> get metrics =>
      (_$metricsComputed ??= Computed<List<HealthMetric>>(
        () => super.metrics,
        name: '_PlantDetailStore.metrics',
      )).value;
  Computed<List<HealthPoint>>? _$trendSeriesComputed;

  @override
  List<HealthPoint> get trendSeries =>
      (_$trendSeriesComputed ??= Computed<List<HealthPoint>>(
        () => super.trendSeries,
        name: '_PlantDetailStore.trendSeries',
      )).value;
  Computed<List<String>>? _$trendLabelsComputed;

  @override
  List<String> get trendLabels =>
      (_$trendLabelsComputed ??= Computed<List<String>>(
        () => super.trendLabels,
        name: '_PlantDetailStore.trendLabels',
      )).value;
  Computed<bool>? _$hasTrendDataComputed;

  @override
  bool get hasTrendData => (_$hasTrendDataComputed ??= Computed<bool>(
    () => super.hasTrendData,
    name: '_PlantDetailStore.hasTrendData',
  )).value;
  Computed<PlantInsight>? _$latestInsightComputed;

  @override
  PlantInsight get latestInsight =>
      (_$latestInsightComputed ??= Computed<PlantInsight>(
        () => super.latestInsight,
        name: '_PlantDetailStore.latestInsight',
      )).value;
  Computed<String>? _$attentionHeadlineComputed;

  @override
  String get attentionHeadline =>
      (_$attentionHeadlineComputed ??= Computed<String>(
        () => super.attentionHeadline,
        name: '_PlantDetailStore.attentionHeadline',
      )).value;
  Computed<String>? _$attentionBodyComputed;

  @override
  String get attentionBody => (_$attentionBodyComputed ??= Computed<String>(
    () => super.attentionBody,
    name: '_PlantDetailStore.attentionBody',
  )).value;
  Computed<List<NextAction>>? _$nextActionsComputed;

  @override
  List<NextAction> get nextActions =>
      (_$nextActionsComputed ??= Computed<List<NextAction>>(
        () => super.nextActions,
        name: '_PlantDetailStore.nextActions',
      )).value;

  late final _$plantAtom = Atom(
    name: '_PlantDetailStore.plant',
    context: context,
  );

  @override
  Plant? get plant {
    _$plantAtom.reportRead();
    return super.plant;
  }

  @override
  set plant(Plant? value) {
    _$plantAtom.reportWrite(value, super.plant, () {
      super.plant = value;
    });
  }

  late final _$stateAtom = Atom(
    name: '_PlantDetailStore.state',
    context: context,
  );

  @override
  LoadState get state {
    _$stateAtom.reportRead();
    return super.state;
  }

  @override
  set state(LoadState value) {
    _$stateAtom.reportWrite(value, super.state, () {
      super.state = value;
    });
  }

  late final _$errorMessageAtom = Atom(
    name: '_PlantDetailStore.errorMessage',
    context: context,
  );

  @override
  String? get errorMessage {
    _$errorMessageAtom.reportRead();
    return super.errorMessage;
  }

  @override
  set errorMessage(String? value) {
    _$errorMessageAtom.reportWrite(value, super.errorMessage, () {
      super.errorMessage = value;
    });
  }

  late final _$rangeAtom = Atom(
    name: '_PlantDetailStore.range',
    context: context,
  );

  @override
  TrendRange get range {
    _$rangeAtom.reportRead();
    return super.range;
  }

  @override
  set range(TrendRange value) {
    _$rangeAtom.reportWrite(value, super.range, () {
      super.range = value;
    });
  }

  late final _$isBusyAtom = Atom(
    name: '_PlantDetailStore.isBusy',
    context: context,
  );

  @override
  bool get isBusy {
    _$isBusyAtom.reportRead();
    return super.isBusy;
  }

  @override
  set isBusy(bool value) {
    _$isBusyAtom.reportWrite(value, super.isBusy, () {
      super.isBusy = value;
    });
  }

  late final _$justWateredAtom = Atom(
    name: '_PlantDetailStore.justWatered',
    context: context,
  );

  @override
  bool get justWatered {
    _$justWateredAtom.reportRead();
    return super.justWatered;
  }

  @override
  set justWatered(bool value) {
    _$justWateredAtom.reportWrite(value, super.justWatered, () {
      super.justWatered = value;
    });
  }

  late final _$environmentDetailAtom = Atom(
    name: '_PlantDetailStore.environmentDetail',
    context: context,
  );

  @override
  String get environmentDetail {
    _$environmentDetailAtom.reportRead();
    return super.environmentDetail;
  }

  @override
  set environmentDetail(String value) {
    _$environmentDetailAtom.reportWrite(value, super.environmentDetail, () {
      super.environmentDetail = value;
    });
  }

  late final _$environmentStatusAtom = Atom(
    name: '_PlantDetailStore.environmentStatus',
    context: context,
  );

  @override
  MetricStatus get environmentStatus {
    _$environmentStatusAtom.reportRead();
    return super.environmentStatus;
  }

  @override
  set environmentStatus(MetricStatus value) {
    _$environmentStatusAtom.reportWrite(value, super.environmentStatus, () {
      super.environmentStatus = value;
    });
  }

  late final _$loadPlantDetailsAsyncAction = AsyncAction(
    '_PlantDetailStore.loadPlantDetails',
    context: context,
  );

  @override
  Future<void> loadPlantDetails(String plantId) {
    return _$loadPlantDetailsAsyncAction.run(
      () => super.loadPlantDetails(plantId),
    );
  }

  late final _$markAsWateredAsyncAction = AsyncAction(
    '_PlantDetailStore.markAsWatered',
    context: context,
  );

  @override
  Future<void> markAsWatered() {
    return _$markAsWateredAsyncAction.run(() => super.markAsWatered());
  }

  late final _$resumeActiveCareAsyncAction = AsyncAction(
    '_PlantDetailStore.resumeActiveCare',
    context: context,
  );

  @override
  Future<void> resumeActiveCare() {
    return _$resumeActiveCareAsyncAction.run(() => super.resumeActiveCare());
  }

  late final _$setReminderAsyncAction = AsyncAction(
    '_PlantDetailStore.setReminder',
    context: context,
  );

  @override
  Future<void> setReminder({bool? watering, bool? checkIn}) {
    return _$setReminderAsyncAction.run(
      () => super.setReminder(watering: watering, checkIn: checkIn),
    );
  }

  late final _$_PlantDetailStoreActionController = ActionController(
    name: '_PlantDetailStore',
    context: context,
  );

  @override
  void setRange(TrendRange value) {
    final _$actionInfo = _$_PlantDetailStoreActionController.startAction(
      name: '_PlantDetailStore.setRange',
    );
    try {
      return super.setRange(value);
    } finally {
      _$_PlantDetailStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setEnvironment(String detail, MetricStatus status) {
    final _$actionInfo = _$_PlantDetailStoreActionController.startAction(
      name: '_PlantDetailStore.setEnvironment',
    );
    try {
      return super.setEnvironment(detail, status);
    } finally {
      _$_PlantDetailStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void attach(Plant value) {
    final _$actionInfo = _$_PlantDetailStoreActionController.startAction(
      name: '_PlantDetailStore.attach',
    );
    try {
      return super.attach(value);
    } finally {
      _$_PlantDetailStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void applyUpdatedPlant(Plant updated) {
    final _$actionInfo = _$_PlantDetailStoreActionController.startAction(
      name: '_PlantDetailStore.applyUpdatedPlant',
    );
    try {
      return super.applyUpdatedPlant(updated);
    } finally {
      _$_PlantDetailStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
plant: ${plant},
state: ${state},
errorMessage: ${errorMessage},
range: ${range},
isBusy: ${isBusy},
justWatered: ${justWatered},
environmentDetail: ${environmentDetail},
environmentStatus: ${environmentStatus},
isLoading: ${isLoading},
healthScore: ${healthScore},
band: ${band},
careStatus: ${careStatus},
isPaused: ${isPaused},
bandLabel: ${bandLabel},
weeklyChange: ${weeklyChange},
streakWeeks: ${streakWeeks},
updateCount: ${updateCount},
wateringMetric: ${wateringMetric},
lightMetric: ${lightMetric},
environmentMetric: ${environmentMetric},
conditionMetric: ${conditionMetric},
metrics: ${metrics},
trendSeries: ${trendSeries},
trendLabels: ${trendLabels},
hasTrendData: ${hasTrendData},
latestInsight: ${latestInsight},
attentionHeadline: ${attentionHeadline},
attentionBody: ${attentionBody},
nextActions: ${nextActions}
    ''';
  }
}
