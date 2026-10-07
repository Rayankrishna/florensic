import '../core/json.dart';

/// The signed-in keeper.
class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.city,
    required this.plantsKept,
    required this.underActiveCare,
    required this.averageHealth,
    required this.careStreakWeeks,
    required this.streakSince,
    required this.reminderTime,
    required this.units,
    this.timezone = 'UTC',
  });

  /// `GET /v1/me` — profile plus the server-computed stats.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final stats = Json.map(json['stats']);
    return UserProfile(
      name: Json.str(json['name']),
      email: Json.str(json['email']),
      city: Json.str(json['city'], '—'),
      plantsKept: Json.integer(stats['plants_kept']),
      underActiveCare: Json.integer(stats['under_active_care']),
      averageHealth: Json.integer(stats['average_health']),
      careStreakWeeks: Json.integer(stats['care_streak_weeks']),
      // No backend field yet (§4.7).
      streakSince: Json.str(json['streak_since'], 'the start'),
      reminderTime: Json.str(json['reminder_time'], '08:00'),
      units: Json.str(json['units']) == 'imperial' ? '°F · oz' : '°C · ml',
      timezone: Json.str(json['timezone'], 'UTC'),
    );
  }

  final String name;
  final String email;
  final String city;
  final int plantsKept;
  final int underActiveCare;
  final int averageHealth;
  final int careStreakWeeks;

  /// e.g. `February`.
  final String streakSince;
  final String reminderTime;
  final String units;

  /// IANA zone the server dates the owner's days on; `UTC` until set.
  final String timezone;

  String get initial => name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();

  UserProfile copyWith({
    String? name,
    String? email,
    int? plantsKept,
    int? underActiveCare,
    int? averageHealth,
    String? timezone,
  }) =>
      UserProfile(
        name: name ?? this.name,
        email: email ?? this.email,
        city: city,
        plantsKept: plantsKept ?? this.plantsKept,
        underActiveCare: underActiveCare ?? this.underActiveCare,
        averageHealth: averageHealth ?? this.averageHealth,
        careStreakWeeks: careStreakWeeks,
        streakSince: streakSince,
        reminderTime: reminderTime,
        units: units,
        timezone: timezone ?? this.timezone,
      );
}
