import '../../enum.dart';

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

  final DateTime nextWatering;
  final int nextWaterAmountMl;
  final int frequencyDays;
  final DateTime lastWatered;
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
  });

  final CareEventType type;
  final String title;
  final String detail;
  final DateTime at;
}
