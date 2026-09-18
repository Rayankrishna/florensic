import 'package:mobx/mobx.dart';

import '../domain/models/plant_insight.dart';
import '../domain/models/weather_data.dart';
import '../domain/repositories/insights_repository.dart';
import '../enum.dart';

part 'insights_store.g.dart';

class InsightsStore = _InsightsStore with _$InsightsStore;

abstract class _InsightsStore with Store {
  _InsightsStore(this._repository);

  final InsightsRepository _repository;

  @observable
  WeatherData? weather;

  @observable
  ObservableList<EnvironmentalInsight> insights =
      ObservableList<EnvironmentalInsight>();

  @observable
  ObservableList<EnvPoint> environmentHistory = ObservableList<EnvPoint>();

  @observable
  HealthCorrelation? correlation;

  @observable
  HomeEnvironmentInsight? homeInsight;

  @observable
  LoadState state = LoadState.idle;

  @observable
  String? errorMessage;

  @computed
  bool get isLoading => state == LoadState.loading;

  @computed
  int get newInsightCount => insights.where((i) => i.isNew).length;

  @computed
  String get city => weather?.city ?? '—';

  /// Ambient summary shared with the plant dashboard's Environment metric.
  @computed
  String get environmentSummary {
    final w = weather;
    if (w == null) return '—';
    return '${w.temperatureC}°C · ${w.humidity}% humidity';
  }

  @computed
  MetricStatus get environmentStatus {
    final w = weather;
    if (w == null) return MetricStatus.neutral;
    if (w.temperatureC >= 34 || w.humidity < 35) return MetricStatus.bad;
    if (w.temperatureC >= 30) return MetricStatus.watch;
    return MetricStatus.good;
  }

  @action
  Future<void> loadInsights({bool force = false}) async {
    if (state == LoadState.loading) return;
    if (!force && state == LoadState.ready) return;
    state = LoadState.loading;
    errorMessage = null;
    try {
      final results = await Future.wait<Object>([
        _repository.loadWeather(),
        _repository.loadInsights(),
        _repository.loadEnvironmentHistory(),
        _repository.loadCorrelation(),
        _repository.loadHomeInsight(),
      ]);
      weather = results[0] as WeatherData;
      insights = ObservableList<EnvironmentalInsight>.of(
          results[1] as List<EnvironmentalInsight>);
      environmentHistory =
          ObservableList<EnvPoint>.of(results[2] as List<EnvPoint>);
      correlation = results[3] as HealthCorrelation;
      homeInsight = results[4] as HomeEnvironmentInsight;
      state = LoadState.ready;
    } catch (e) {
      errorMessage = e.toString();
      state = LoadState.error;
    }
  }
}
