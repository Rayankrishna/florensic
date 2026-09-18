import '../../enum.dart';
import '../models/care_task.dart';
import '../models/plant.dart';
import '../models/plant_care_schedule.dart';
import '../models/plant_condition_update.dart';
import '../models/plant_health.dart';
import '../models/plant_species.dart';
import 'mock/mock_api_client.dart';
import 'mock/mock_collection.dart';
import '../../utils/app_clock.dart';

/// The keeper's collection.
abstract class PlantRepository {
  Future<List<Plant>> loadPlants();

  Future<List<CareTask>> loadTodaysCare();

  Future<Plant> markAsWatered(String plantId);

  Future<Plant> submitConditionUpdate(
    String plantId, {
    required ConditionVerdict verdict,
    required List<String> observations,
    required String note,
  });

  Future<Plant> resumeActiveCare(String plantId);

  /// Adds [species] to the collection. [nickname] is what the keeper calls
  /// this particular plant; blank falls back to the species' common name.
  Future<Plant> addPlant(PlantSpecies species, {String? nickname});

  Future<void> removePlant(String plantId);

  Future<Plant> setReminder(String plantId,
      {bool? watering, bool? checkIn});

  Future<void> completeTask(String taskId);
}

/// In-memory implementation backed by [MockCollection].
///
/// Health scoring here is a deterministic stand-in, not a model of plant
/// physiology: a verdict moves the score by a fixed amount and watering on
/// time nudges it up. Replace with the scoring service when it lands.
class MockPlantRepository implements PlantRepository {
  MockPlantRepository(this._client);

  final MockApiClient _client;

  List<Plant>? _plants;
  List<CareTask>? _tasks;

  List<Plant> get _collection => _plants ??= MockCollection.build();

  @override
  Future<List<Plant>> loadPlants() =>
      _client.send('/plants', () => List<Plant>.unmodifiable(_collection),
          failsWhenOffline: false);

  @override
  Future<List<CareTask>> loadTodaysCare() => _client.send(
        '/plants/today',
        () => List<CareTask>.unmodifiable(
            _tasks ??= MockCollection.tasks(_collection)),
        failsWhenOffline: false,
      );

  int _indexOf(String id) => _collection.indexWhere((p) => p.id == id);

  Plant _replace(int index, Plant updated) {
    _collection[index] = updated;
    return updated;
  }

  @override
  Future<Plant> markAsWatered(String plantId) => _client.send(
        '/plants/$plantId/water',
        () {
          final i = _indexOf(plantId);
          final plant = _collection[i];
          final now = AppClock.now();
          final today = DateTime(now.year, now.month, now.day);
          final schedule = plant.schedule.copyWith(
            lastWatered: now,
            lastAmountMl: plant.schedule.nextWaterAmountMl,
            nextWatering:
                today.add(Duration(days: plant.schedule.frequencyDays)),
          );
          final wasOverdue = plant.daysUntilWatering < 0;
          final score = plant.healthScore == null
              ? null
              : (plant.healthScore! + (wasOverdue ? 2 : 1)).clamp(1, 100);
          return _replace(
            i,
            plant.copyWith(
              schedule: schedule,
              healthScore: score,
              leafDropReported: false,
              history: _appendPoint(plant.history, score),
              careHistory: [
                CareEvent(
                  type: CareEventType.watered,
                  title: 'Watered · ${plant.schedule.nextWaterAmountMl} ml',
                  detail: 'Logged from the app',
                  at: now,
                ),
                ...plant.careHistory,
              ],
            ),
          );
        },
        failsWhenOffline: false,
      );

  @override
  Future<Plant> submitConditionUpdate(
    String plantId, {
    required ConditionVerdict verdict,
    required List<String> observations,
    required String note,
  }) =>
      _client.send(
        '/plants/$plantId/condition',
        () {
          final i = _indexOf(plantId);
          final plant = _collection[i];
          final now = AppClock.now();
          final today = DateTime(now.year, now.month, now.day);
          final base = plant.healthScore ?? 70;
          final score = (base + verdict.scoreDelta).clamp(1, 100);
          final update = ConditionUpdate(
            id: '$plantId-${now.microsecondsSinceEpoch}',
            plantId: plantId,
            takenAt: now,
            verdict: verdict,
            observations: observations,
            note: note,
            scoreDelta: verdict.scoreDelta,
          );
          final schedule = plant.schedule.copyWith(
            checkInWindowOpens: today
                .add(Duration(days: plant.schedule.checkInIntervalDays)),
          );
          return _replace(
            i,
            plant.copyWith(
              healthScore: score,
              careStatus: CareStatus.active,
              schedule: schedule,
              updates: [...plant.updates, update],
              history: _appendPoint(plant.history, score),
              photoCount: plant.photoCount + 1,
              streakWeeks: plant.streakWeeks + 1,
              leafDropReported: verdict == ConditionVerdict.healthy
                  ? false
                  : plant.leafDropReported,
              careHistory: [
                CareEvent(
                  type: CareEventType.conditionUpdate,
                  title: 'Condition update · ${verdict.title}',
                  detail: note.isEmpty
                      ? (observations.isEmpty
                          ? 'No notes'
                          : observations.join(' · '))
                      : note,
                  at: now,
                ),
                ...plant.careHistory,
              ],
            ),
          );
        },
        failsWhenOffline: false,
      );

  @override
  Future<Plant> resumeActiveCare(String plantId) => _client.send(
        '/plants/$plantId/resume',
        () {
          final i = _indexOf(plantId);
          final plant = _collection[i];
          final now = AppClock.now();
          final today = DateTime(now.year, now.month, now.day);
          return _replace(
            i,
            plant.copyWith(
              careStatus: CareStatus.active,
              healthScore: 70,
              streakWeeks: plant.streakWeeks,
              schedule: plant.schedule.copyWith(
                checkInWindowOpens: today
                    .add(Duration(days: plant.schedule.checkInIntervalDays)),
              ),
              history: [HealthPoint(date: today, score: 70)],
            ),
          );
        },
        failsWhenOffline: false,
      );

  @override
  Future<Plant> addPlant(PlantSpecies species, {String? nickname}) =>
      _client.send(
        '/plants',
        () {
          final name = (nickname ?? '').trim();
          final now = AppClock.now();
          final today = DateTime(now.year, now.month, now.day);
          final interval = species.wateringIntervalDays;
          final plant = Plant(
            id: 'p-${species.id}-${now.microsecondsSinceEpoch}',
            species: species,
            nickname: name.isEmpty ? species.commonName : name,
            room: 'Unassigned',
            indoor: true,
            addedOn: now,
            healthScore: 80,
            careStatus: CareStatus.active,
            schedule: CareSchedule(
              nextWatering: today.add(Duration(days: interval)),
              nextWaterAmountMl: 220,
              frequencyDays: interval,
              lastWatered: now,
              lastAmountMl: 0,
              checkInIntervalDays: 14,
              checkInWindowDays: 3,
              checkInWindowOpens: today.add(const Duration(days: 14)),
              wateringReminder: true,
              checkInReminder: true,
              reminderTime: '08:00',
            ),
            history: [HealthPoint(date: today, score: 80)],
            updates: const [],
            careHistory: [
              CareEvent(
                type: CareEventType.conditionUpdate,
                title: 'Added to collection',
                detail: 'Care schedule starts tomorrow',
                at: now,
              ),
            ],
            photoCount: 0,
            streakWeeks: 0,
            lightStatus: MetricStatus.good,
            lightDetail: species.light,
          );
          _collection.insert(0, plant);
          _tasks = null;
          return plant;
        },
        failsWhenOffline: false,
      );

  @override
  Future<void> removePlant(String plantId) => _client.send(
        '/plants/$plantId/delete',
        () {
          _collection.removeWhere((p) => p.id == plantId);
          _tasks?.removeWhere((t) => t.plantId == plantId);
        },
        failsWhenOffline: false,
      );

  @override
  Future<Plant> setReminder(String plantId, {bool? watering, bool? checkIn}) =>
      _client.send(
        '/plants/$plantId/reminders',
        () {
          final i = _indexOf(plantId);
          final plant = _collection[i];
          return _replace(
            i,
            plant.copyWith(
              schedule: plant.schedule.copyWith(
                wateringReminder: watering,
                checkInReminder: checkIn,
              ),
            ),
          );
        },
        failsWhenOffline: false,
      );

  @override
  Future<void> completeTask(String taskId) => _client.send(
        '/tasks/$taskId/complete',
        () {
          final tasks = _tasks;
          if (tasks == null) return;
          final i = tasks.indexWhere((t) => t.id == taskId);
          if (i == -1) return;
          final now = AppClock.now();
          tasks[i] = tasks[i].copyWith(
            done: true,
            doneAt: '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
          );
        },
        failsWhenOffline: false,
      );

  static List<HealthPoint> _appendPoint(List<HealthPoint> history, int? score) {
    if (score == null) return history;
    final now = AppClock.now();
    final today = DateTime(now.year, now.month, now.day);
    final trimmed = history.where((p) => p.date.isBefore(today)).toList();
    return [...trimmed, HealthPoint(date: today, score: score)];
  }
}
