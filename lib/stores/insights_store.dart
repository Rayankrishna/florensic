import 'package:mobx/mobx.dart';

import '../domain/models/plant_insight.dart';
import '../domain/models/weather_data.dart';
import '../domain/repositories/insights_repository.dart';
import '../enum.dart';
import '../interceptors/api_interceptor.dart';
import '../utils/app_log.dart';

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

  /// Shown wherever weather-driven text appears (`meta.attribution`).
  @observable
  String attribution = 'Weather data by Open-Meteo.com (CC BY 4.0)';

  /// True when the backend has no weather reading for this build.
  @computed
  bool get weatherUnavailable => state == LoadState.ready && weather == null;

  /// True when there is no environment history to chart yet.
  @computed
  bool get historyUnavailable =>
      state == LoadState.ready && environmentHistory.isEmpty;

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

    List<Object?> resp;
    try {
      resp = await Future.wait<Object?>([
        _repository.loadWeather(),
        _repository.loadInsights(),
        _repository.loadEnvironmentHistory(),
        _repository.loadCorrelation(),
        _repository.loadHomeInsight(),
      ]);
    } catch (e, stack) {
      AppLog.e('loading insights failed',
          name: 'insights', error: e, stackTrace: stack);
      runInAction(() {
        errorMessage = e is ApiException ? e.message : e.toString();
        if (insights.isEmpty) state = LoadState.error;
      });
      return;
    }

    runInAction(() {
      weather = resp[0] as WeatherData?;
      insights = ObservableList<EnvironmentalInsight>.of(
          resp[1]! as List<EnvironmentalInsight>);
      environmentHistory =
          ObservableList<EnvPoint>.of(resp[2]! as List<EnvPoint>);
      correlation = resp[3] as HealthCorrelation?;
      homeInsight = resp[4] as HomeEnvironmentInsight?;
      attribution = _repository.attribution;
      state = LoadState.ready;
    });
  }
}
