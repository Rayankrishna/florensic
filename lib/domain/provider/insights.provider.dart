import '../core/json.dart';
import '../core/services_config.dart';
import '../models/plant_insight.dart';

/// The insights response, which carries the day's items, the humidity
/// correlation and the attribution the screen must display.
class InsightsPayload {
  const InsightsPayload({
    required this.items,
    required this.correlation,
    required this.attribution,
  });

  final List<EnvironmentalInsight> items;
  final HealthCorrelation? correlation;
  final String attribution;
}

/// `/v1/insights`.
class InsightsProvider {
  const InsightsProvider();

  HttpClient get _http => http!;

  Future<InsightsPayload> load() => _http.get('/insights', (json) {
        final map = Json.map(json);
        return InsightsPayload(
          items: Json.list(map['items'])
              .map(EnvironmentalInsight.fromJson)
              .toList(),
          correlation: HealthCorrelation.fromJson(
              map['correlation'] == null ? null : Json.map(map['correlation'])),
          attribution: Json.str(
            Json.map(map['meta'])['attribution'],
            'Weather data by Open-Meteo.com (CC BY 4.0)',
          ),
        );
      });
}
