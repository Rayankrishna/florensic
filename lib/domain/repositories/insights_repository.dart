import '../models/plant_insight.dart';
import '../models/weather_data.dart';

abstract class InsightsRepository {
  Future<List<EnvironmentalInsight>> loadInsights();

  Future<HealthCorrelation?> loadCorrelation();

  Future<HomeEnvironmentInsight?> loadHomeInsight();

  /// `null` while the backend has no weather endpoint — the screens show an
  /// unavailable state rather than a made-up reading.
  Future<WeatherData?> loadWeather();

  /// Empty for the same reason.
  Future<List<EnvPoint>> loadEnvironmentHistory();

  /// `meta.attribution`, shown wherever weather-driven text appears.
  String get attribution;
}
