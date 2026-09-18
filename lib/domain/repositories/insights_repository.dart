import '../../enum.dart';
import '../models/plant_insight.dart';
import '../models/weather_data.dart';
import 'mock/mock_api_client.dart';
import '../../utils/app_clock.dart';

abstract class InsightsRepository {
  Future<WeatherData> loadWeather();

  Future<List<EnvironmentalInsight>> loadInsights();

  Future<List<EnvPoint>> loadEnvironmentHistory();

  Future<HealthCorrelation> loadCorrelation();

  Future<HomeEnvironmentInsight> loadHomeInsight();
}

class MockInsightsRepository implements InsightsRepository {
  MockInsightsRepository(this._client);

  final MockApiClient _client;

  static const WeatherData _weather = WeatherData(
    city: 'Mumbai',
    temperatureC: 31,
    feelsLikeC: 34,
    condition: 'Hazy sun',
    humidity: 68,
    rainChance: 15,
    uvIndex: 7,
    windKph: 9,
  );

  @override
  Future<WeatherData> loadWeather() =>
      _client.send('/weather', () => _weather);

  @override
  Future<List<EnvironmentalInsight>> loadInsights() => _client.send(
        '/insights',
        () => const [
          EnvironmentalInsight(
            id: 'i-heat',
            title: 'Warm conditions today',
            body: 'Your tropical plants may need more frequent moisture checks '
                '— four plants affected.',
            kind: InsightKind.heat,
          ),
          EnvironmentalInsight(
            id: 'i-light',
            title: 'Low light conditions',
            body: 'Your low-light plants are likely comfortable, but watch '
                'growth over the coming weeks.',
            kind: InsightKind.light,
          ),
          EnvironmentalInsight(
            id: 'i-rain',
            title: 'Rain expected tomorrow',
            body: 'Outdoor plants may need less manual watering — two schedules '
                'shifted automatically.',
            kind: InsightKind.rain,
          ),
        ],
      );

  @override
  Future<List<EnvPoint>> loadEnvironmentHistory() => _client.send(
        '/insights/history',
        () {
          final now = AppClock.now();
          const temps = [27.5, 28.1, 29.4, 29.0, 30.2, 30.6, 31.0];
          const humidity = [74.0, 72.0, 71.5, 69.0, 68.5, 66.0, 68.0];
          return List.generate(7, (i) {
            final day = now.subtract(Duration(days: 6 - i));
            return EnvPoint(
              day: day.day,
              temperatureC: temps[i],
              humidity: humidity[i],
            );
          });
        },
      );

  @override
  Future<HealthCorrelation> loadCorrelation() => _client.send(
        '/insights/correlation',
        () => const HealthCorrelation(
          headline: 'Humidity above 60% tracks with your best health scores.',
          body: 'Across 9 weeks of updates, your tropical plants score 11 points '
              'higher on humid weeks. A pebble tray through the dry season '
              'should hold the gain.',
          humidWeeksScore: 86,
          dryWeeksScore: 75,
        ),
      );

  @override
  Future<HomeEnvironmentInsight> loadHomeInsight() => _client.send(
        '/insights/home',
        () => const HomeEnvironmentInsight(
          title: 'Warm conditions today',
          body: 'Your tropical plants may need closer attention to moisture '
              'through the afternoon.',
          tone: MetricStatus.watch,
        ),
      );
}
