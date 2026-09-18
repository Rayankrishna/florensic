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
  });

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

  String get initial => name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();

  UserProfile copyWith({
    String? name,
    String? email,
    int? plantsKept,
    int? underActiveCare,
    int? averageHealth,
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
      );
}
