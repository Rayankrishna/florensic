import '../../enum.dart';
import '../core/json.dart';

/// Everything the Care schedule screen renders for one plant.
class CareSchedule {
  const CareSchedule({
    required this.nextWatering,
    required this.nextWaterAmountMl,
    required this.frequencyDays,
    required this.lastWatered,
    required this.lastAmountMl,
    required this.checkInIntervalDays,
    required this.checkInWindowDays,
    required this.checkInWindowOpens,
    required this.wateringReminder,
    required this.checkInReminder,
    required this.reminderTime,
  });

  factory CareSchedule.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return CareSchedule(
      // Owner-local dates: read as written.
      nextWatering: Json.day(json['next_watering'], now),
      nextWaterAmountMl: Json.integer(json['next_water_amount_ml'], 200),
      frequencyDays: Json.integer(json['frequency_days'], 7),
      // Null until the first watering is logged.
      lastWatered: Json.dateOrNull(json['last_watered']),
      lastAmountMl: Json.integer(json['last_amount_ml']),
      checkInIntervalDays: Json.integer(json['check_in_interval_days'], 14),
      checkInWindowDays: Json.integer(json['check_in_window_days'], 3),
      checkInWindowOpens: Json.day(json['check_in_window_opens'], now),
      wateringReminder: Json.boolean(json['watering_reminder'], true),
      checkInReminder: Json.boolean(json['check_in_reminder'], true),
      reminderTime: Json.str(json['reminder_time'], '08:00'),
    );
  }

  final DateTime nextWatering;
  final int nextWaterAmountMl;
  final int frequencyDays;

  /// Null when no watering has been logged yet.
  final DateTime? lastWatered;
  final int lastAmountMl;
  final int checkInIntervalDays;
  final int checkInWindowDays;
  final DateTime checkInWindowOpens;
  final bool wateringReminder;
  final bool checkInReminder;

  /// `08:00`.
  final String reminderTime;

  CareSchedule copyWith({
    DateTime? nextWatering,
    DateTime? lastWatered,
    int? lastAmountMl,
    DateTime? checkInWindowOpens,
    bool? wateringReminder,
    bool? checkInReminder,
  }) {
    return CareSchedule(
      nextWatering: nextWatering ?? this.nextWatering,
      nextWaterAmountMl: nextWaterAmountMl,
      frequencyDays: frequencyDays,
      lastWatered: lastWatered ?? this.lastWatered,
      lastAmountMl: lastAmountMl ?? this.lastAmountMl,
      checkInIntervalDays: checkInIntervalDays,
      checkInWindowDays: checkInWindowDays,
      checkInWindowOpens: checkInWindowOpens ?? this.checkInWindowOpens,
      wateringReminder: wateringReminder ?? this.wateringReminder,
      checkInReminder: checkInReminder ?? this.checkInReminder,
      reminderTime: reminderTime,
    );
  }
}

/// A row in `Care history`.
class CareEvent {
  const CareEvent({
    required this.type,
    required this.title,
    required this.detail,
    required this.at,
    this.rawType = '',
  });

  factory CareEvent.fromJson(Map<String, dynamic> json) {
    final raw = Json.str(json['type']);
    return CareEvent(
      type: raw.startsWith('treatment_')
          ? CareEventType.treatment
          : Json.enumOf(raw, CareEventType.values, CareEventType.other),
      rawType: raw,
      title: Json.str(json['title']),
      detail: Json.str(json['detail']),
      at: Json.date(json['at']),
    );
  }

  final CareEventType type;

  /// The server's own type name, e.g. `treatment_escalated`.
  final String rawType;
  final String title;
  final String detail;
  final DateTime at;

  /// The server's title, or a readable stand-in for a type sent without one.
  String get label {
    if (title.isNotEmpty) return title;
    if (rawType.isEmpty) return 'Care update';
    final words = rawType.replaceAll('_', ' ');
    return words[0].toUpperCase() + words.substring(1);
  }
}
