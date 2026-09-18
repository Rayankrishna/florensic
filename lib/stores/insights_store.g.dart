// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insights_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$InsightsStore on _InsightsStore, Store {
  Computed<bool>? _$isLoadingComputed;

  @override
  bool get isLoading => (_$isLoadingComputed ??= Computed<bool>(
    () => super.isLoading,
    name: '_InsightsStore.isLoading',
  )).value;
  Computed<int>? _$newInsightCountComputed;

  @override
  int get newInsightCount => (_$newInsightCountComputed ??= Computed<int>(
    () => super.newInsightCount,
    name: '_InsightsStore.newInsightCount',
  )).value;
  Computed<String>? _$cityComputed;

  @override
  String get city => (_$cityComputed ??= Computed<String>(
    () => super.city,
    name: '_InsightsStore.city',
  )).value;
  Computed<String>? _$environmentSummaryComputed;

  @override
  String get environmentSummary =>
      (_$environmentSummaryComputed ??= Computed<String>(
        () => super.environmentSummary,
        name: '_InsightsStore.environmentSummary',
      )).value;
  Computed<MetricStatus>? _$environmentStatusComputed;

  @override
  MetricStatus get environmentStatus =>
      (_$environmentStatusComputed ??= Computed<MetricStatus>(
        () => super.environmentStatus,
        name: '_InsightsStore.environmentStatus',
      )).value;

  late final _$weatherAtom = Atom(
    name: '_InsightsStore.weather',
    context: context,
  );

  @override
  WeatherData? get weather {
    _$weatherAtom.reportRead();
    return super.weather;
  }

  @override
  set weather(WeatherData? value) {
    _$weatherAtom.reportWrite(value, super.weather, () {
      super.weather = value;
    });
  }

  late final _$insightsAtom = Atom(
    name: '_InsightsStore.insights',
    context: context,
  );

  @override
  ObservableList<EnvironmentalInsight> get insights {
    _$insightsAtom.reportRead();
    return super.insights;
  }

  @override
  set insights(ObservableList<EnvironmentalInsight> value) {
    _$insightsAtom.reportWrite(value, super.insights, () {
      super.insights = value;
    });
  }

  late final _$environmentHistoryAtom = Atom(
    name: '_InsightsStore.environmentHistory',
    context: context,
  );

  @override
  ObservableList<EnvPoint> get environmentHistory {
    _$environmentHistoryAtom.reportRead();
    return super.environmentHistory;
  }

  @override
  set environmentHistory(ObservableList<EnvPoint> value) {
    _$environmentHistoryAtom.reportWrite(value, super.environmentHistory, () {
      super.environmentHistory = value;
    });
  }

  late final _$correlationAtom = Atom(
    name: '_InsightsStore.correlation',
    context: context,
  );

  @override
  HealthCorrelation? get correlation {
    _$correlationAtom.reportRead();
    return super.correlation;
  }

  @override
  set correlation(HealthCorrelation? value) {
    _$correlationAtom.reportWrite(value, super.correlation, () {
      super.correlation = value;
    });
  }

  late final _$homeInsightAtom = Atom(
    name: '_InsightsStore.homeInsight',
    context: context,
  );

  @override
  HomeEnvironmentInsight? get homeInsight {
    _$homeInsightAtom.reportRead();
    return super.homeInsight;
  }

  @override
  set homeInsight(HomeEnvironmentInsight? value) {
    _$homeInsightAtom.reportWrite(value, super.homeInsight, () {
      super.homeInsight = value;
    });
  }

  late final _$stateAtom = Atom(name: '_InsightsStore.state', context: context);

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
    name: '_InsightsStore.errorMessage',
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

  late final _$loadInsightsAsyncAction = AsyncAction(
    '_InsightsStore.loadInsights',
    context: context,
  );

  @override
  Future<void> loadInsights({bool force = false}) {
    return _$loadInsightsAsyncAction.run(
      () => super.loadInsights(force: force),
    );
  }

  @override
  String toString() {
    return '''
weather: ${weather},
insights: ${insights},
environmentHistory: ${environmentHistory},
correlation: ${correlation},
homeInsight: ${homeInsight},
state: ${state},
errorMessage: ${errorMessage},
isLoading: ${isLoading},
newInsightCount: ${newInsightCount},
city: ${city},
environmentSummary: ${environmentSummary},
environmentStatus: ${environmentStatus}
    ''';
  }
}
