import '../../../enum.dart';
import '../../models/plant_insight.dart';
import '../../models/weather_data.dart';
import '../../provider/insights.provider.dart';
import '../insights_repository.dart';

// The provider is injected by name for readable call sites.
// ignore_for_file: prefer_initializing_formals

/// `GET /v1/insights` — the daily items and the humidity correlation.
///
/// The weather card and the environment history have no endpoint yet, so
/// those two return nothing and their screens say so. Nothing here is
/// invented.
class RemoteInsightsRepository implements InsightsRepository {
  RemoteInsightsRepository({InsightsProvider provider = const InsightsProvider()})
      : _provider = provider;

  final InsightsProvider _provider;

  InsightsPayload? _last;

  @override
  String get attribution =>
      _last?.attribution ?? 'Weather data by Open-Meteo.com (CC BY 4.0)';

  Future<InsightsPayload> _load() async => _last = await _provider.load();

  @override
  Future<List<EnvironmentalInsight>> loadInsights() async =>
      (await _load()).items;

  @override
  Future<HealthCorrelation?> loadCorrelation() async =>
      (_last ?? await _load()).correlation;

  @override
  Future<HomeEnvironmentInsight?> loadHomeInsight() async {
    final items = (_last ?? await _load()).items;
    if (items.isEmpty) return null;
    final newest = items.first;
    return HomeEnvironmentInsight(
      title: newest.title,
      body: newest.body,
      tone: switch (newest.kind) {
        InsightKind.heat => MetricStatus.watch,
        InsightKind.rain => MetricStatus.good,
        _ => MetricStatus.neutral,
      },
    );
  }

  // ── No endpoint yet ──────────────────────────────────────────────────────

  @override
  Future<WeatherData?> loadWeather() async => null;

  @override
  Future<List<EnvPoint>> loadEnvironmentHistory() async => const [];
}
