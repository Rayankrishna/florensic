/// Current conditions for the keeper's location.
class WeatherData {
  const WeatherData({
    required this.city,
    required this.temperatureC,
    required this.feelsLikeC,
    required this.condition,
    required this.humidity,
    required this.rainChance,
    required this.uvIndex,
    required this.windKph,
  });

  final String city;
  final int temperatureC;
  final int feelsLikeC;

  /// e.g. `Hazy sun`.
  final String condition;
  final int humidity;
  final int rainChance;
  final int uvIndex;
  final int windKph;

  String get uvLabel => switch (uvIndex) {
        <= 2 => '$uvIndex low',
        <= 5 => '$uvIndex moderate',
        <= 7 => '$uvIndex high',
        _ => '$uvIndex extreme',
      };
}

/// One day on the environmental-history chart.
class EnvPoint {
  const EnvPoint({
    required this.day,
    required this.temperatureC,
    required this.humidity,
  });

  final int day;
  final double temperatureC;
  final double humidity;
}
