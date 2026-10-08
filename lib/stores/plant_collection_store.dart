import 'package:mobx/mobx.dart';

import '../domain/models/care_task.dart';
import '../domain/models/plant.dart';
import '../domain/models/plant_species.dart';
import '../domain/repositories/plant_repository.dart';
import '../domain/models/plant_health.dart';
import '../enum.dart';
import '../interceptors/api_interceptor.dart';
import '../utils/app_log.dart';
import '../utils/app_clock.dart';

part 'plant_collection_store.g.dart';

class PlantCollectionStore = _PlantCollectionStore with _$PlantCollectionStore;

abstract class _PlantCollectionStore with Store {
  _PlantCollectionStore(this._repository);

  final PlantRepository _repository;

  @observable
  ObservableList<Plant> plants = ObservableList<Plant>();

  @observable
  ObservableList<CareTask> tasks = ObservableList<CareTask>();

  @observable
  LoadState state = LoadState.idle;

  @observable
  String? errorMessage;

  @observable
  String searchQuery = '';

  @observable
  PlantFilter selectedFilter = PlantFilter.all;

  /// Set while a card action is in flight so the UI can disable it.
  @observable
  String? busyPlantId;

  @computed
  bool get isLoading => state == LoadState.loading;

  @computed
  bool get isEmpty =>
      state == LoadState.empty ||
      (state == LoadState.ready && plants.isEmpty);

  @computed
  List<Plant> get filteredPlants {
    final q = searchQuery.trim().toLowerCase();
    return plants.where((p) {
      final matchesQuery = q.isEmpty ||
          p.nickname.toLowerCase().contains(q) ||
          p.latinName.toLowerCase().contains(q) ||
          p.room.toLowerCase().contains(q);
      final matchesFilter = switch (selectedFilter) {
        PlantFilter.all => true,
        PlantFilter.indoor => p.indoor,
        PlantFilter.outdoor => !p.indoor,
        PlantFilter.needsAttention => p.needsAttention,
      };
      return matchesQuery && matchesFilter;
    }).toList(growable: false);
  }

  @computed
  List<Plant> get needsAttention =>
      plants.where((p) => p.needsAttention && !p.paused).toList(growable: false);

  @computed
  int get attentionCount => needsAttention.length;

  @computed
  List<CareTask> get openTasks => tasks.where((t) => !t.done).toList();

  @computed
  int get doneTaskCount => tasks.where((t) => t.done).length;

  @computed
  bool get allCaughtUp => tasks.isNotEmpty && openTasks.isEmpty;

  @computed
  List<Plant> get recentlyAdded {
    final sorted = [...plants]..sort((a, b) => b.addedOn.compareTo(a.addedOn));
    return sorted.take(3).toList(growable: false);
  }

  /// Plants under care: active and stale, never paused.
  @computed
  List<Plant> get underCare =>
      plants.where((p) => !p.paused).toList(growable: false);

  /// Averages the scored plants under care, as `stats.average_health` does;
  /// `null` when none of them has been scored yet.
  @computed
  int? get averageHealth {
    final scored = underCare.where((p) => p.scored).toList();
    if (scored.isEmpty) return null;
    final total = scored.fold<int>(0, (sum, p) => sum + p.healthScore!);
    return (total / scored.length).round();
  }

  @computed
  int get underActiveCare => underCare.length;

  Plant? plantById(String id) {
    for (final p in plants) {
      if (p.id == id) return p;
    }
    return null;
  }

  @action
  void setSearchQuery(String value) => searchQuery = value;

  @action
  void setFilter(PlantFilter filter) => selectedFilter = filter;

  @action
  Future<void> loadPlants({bool force = false}) async {
    if (state == LoadState.loading) return;
    if (!force && state == LoadState.ready && plants.isNotEmpty) return;
    state = LoadState.loading;
    errorMessage = null;

    List<Plant> resp;
    List<CareTask> todays;
    try {
      resp = await _repository.loadPlants();
      todays = await _repository.loadTodaysCare();
    } catch (e, stack) {
      AppLog.e('loading the collection failed',
          name: 'plants', error: e, stackTrace: stack);
      runInAction(() {
        errorMessage = e is ApiException ? e.message : e.toString();
        // Keep whatever is already on screen; only an empty store goes red.
        if (plants.isEmpty) state = LoadState.error;
      });
      return;
    }

    AppLog.i('loaded ${resp.length} plants, ${todays.length} tasks',
        name: 'plants');
    runInAction(() {
      plants = ObservableList<Plant>.of(resp);
      tasks = ObservableList<CareTask>.of(todays);
      state = plants.isEmpty ? LoadState.empty : LoadState.ready;
    });
  }

  /// Swaps in a fresh copy. A write hands back `risk: null` because it did
  /// not compute one, so the last computed risk is carried over; a plant
  /// that has just been paused loses its environment tasks, so today's list
  /// is refetched.
  @action
  void replacePlant(Plant plant) {
    final i = plants.indexWhere((p) => p.id == plant.id);
    if (i == -1) return;
    final previous = plants[i];
    plants[i] = plant.keepingRiskOf(previous);
    if (plant.paused && !previous.paused) refreshTodaysCare();
  }

  @action
  Future<void> refreshTodaysCare() async {
    try {
      final todays = await _repository.loadTodaysCare();
      runInAction(() => tasks = ObservableList<CareTask>.of(todays));
    } catch (e, stack) {
      AppLog.e("refreshing today's care failed",
          name: 'plants', error: e, stackTrace: stack);
    }
  }

  /// The risk the detail read computed, to show on the detail screen.
  Risk? riskFor(String plantId) => plantById(plantId)?.risk;

  @action
  Future<Plant?> markAsWatered(String plantId) async {
    busyPlantId = plantId;
    try {
      final updated = await _repository.markAsWatered(plantId);
      runInAction(() {
        replacePlant(updated);
        _completeLocalTask('task-water-$plantId');
      });
      return updated;
    } catch (e, stack) {
      AppLog.e('watering failed', name: 'plants', error: e, stackTrace: stack);
      runInAction(
          () => errorMessage = e is ApiException ? e.message : e.toString());
      return null;
    } finally {
      runInAction(() => busyPlantId = null);
    }
  }

  @action
  Future<Plant?> skipWatering(String plantId, WateringSkipReason reason) async {
    busyPlantId = plantId;
    try {
      final updated = await _repository.skipWatering(plantId, reason);
      runInAction(() {
        replacePlant(updated);
        // Only `soil_wet` counts as care given and clears the task.
        if (reason == WateringSkipReason.soilWet) {
          _completeLocalTask('task-water-$plantId');
        }
      });
      return updated;
    } catch (e, stack) {
      AppLog.e('skipping a watering failed',
          name: 'plants', error: e, stackTrace: stack);
      runInAction(
          () => errorMessage = e is ApiException ? e.message : e.toString());
      return null;
    } finally {
      runInAction(() => busyPlantId = null);
    }
  }

  @action
  Future<Plant?> addNote(String plantId, List<NoteChip> chips,
      {String? text}) async {
    busyPlantId = plantId;
    try {
      final updated = await _repository.addNote(plantId, chips, text: text);
      runInAction(() => replacePlant(updated));
      return updated;
    } catch (e, stack) {
      AppLog.e('adding a note failed',
          name: 'plants', error: e, stackTrace: stack);
      runInAction(
          () => errorMessage = e is ApiException ? e.message : e.toString());
      return null;
    } finally {
      runInAction(() => busyPlantId = null);
    }
  }

  @action
  Future<Plant?> addPlant(PlantSpecies species, {String? nickname}) async {
    try {
      final plant = await _repository.addPlant(species, nickname: nickname);
      AppLog.i('added ${plant.nickname}', name: 'plants');
      runInAction(() {
        plants.insert(0, plant);
        state = LoadState.ready;
      });
      return plant;
    } catch (e, stack) {
      AppLog.e('adding a plant failed',
          name: 'plants', error: e, stackTrace: stack);
      runInAction(
          () => errorMessage = e is ApiException ? e.message : e.toString());
      return null;
    }
  }

  @action
  Future<void> removePlant(String plantId) async {
    final removed = plants.where((p) => p.id == plantId).toList();
    plants.removeWhere((p) => p.id == plantId);
    tasks.removeWhere((t) => t.plantId == plantId);
    if (plants.isEmpty) state = LoadState.empty;
    try {
      await _repository.removePlant(plantId);
    } catch (e, stack) {
      AppLog.e('removing a plant failed',
          name: 'plants', error: e, stackTrace: stack);
      // Put it back if the delete failed.
      runInAction(() {
        plants.addAll(removed);
        state = plants.isEmpty ? LoadState.empty : LoadState.ready;
        errorMessage = e is ApiException ? e.message : e.toString();
      });
    }
  }

  /// Ticks a task on today's list. Never throws: a task the server no
  /// longer has on today's list (`404 task_not_found`) just means the list
  /// is stale, so it is refetched; any other failure reverts the tick and
  /// surfaces the message.
  @action
  Future<void> completeTask(String taskId) async {
    final i = tasks.indexWhere((t) => t.id == taskId);
    if (i == -1) {
      // Not on the list we hold (a check-in started from the plant screen,
      // say). The server already knows; just bring the list up to date.
      await refreshTodaysCare();
      return;
    }
    final before = tasks[i];
    if (before.done) return;
    _completeLocalTask(taskId);
    try {
      await _repository.completeTask(taskId);
    } on ApiException catch (e) {
      AppLog.w('completing $taskId failed: ${e.code} — ${e.message}',
          name: 'plants');
      if (e.statusCode == 404) {
        await refreshTodaysCare();
        return;
      }
      runInAction(() {
        final j = tasks.indexWhere((t) => t.id == taskId);
        if (j != -1) tasks[j] = before;
        errorMessage = e.message;
      });
    } catch (e, stack) {
      AppLog.e('completing $taskId failed',
          name: 'plants', error: e, stackTrace: stack);
      runInAction(() {
        final j = tasks.indexWhere((t) => t.id == taskId);
        if (j != -1) tasks[j] = before;
        errorMessage = e.toString();
      });
    }
  }

  /// Treatment steps only. The step is recorded as skipped and leaves today's
  /// list without coming back on its cadence.
  @action
  Future<bool> skipTask(String taskId, {String? reason}) async {
    try {
      await _repository.skipTask(taskId, reason: reason);
      runInAction(() => _completeLocalTask(taskId));
      return true;
    } catch (e, stack) {
      AppLog.e('skipping a task failed',
          name: 'plants', error: e, stackTrace: stack);
      runInAction(
          () => errorMessage = e is ApiException ? e.message : e.toString());
      return false;
    }
  }

  void _completeLocalTask(String taskId) {
    final i = tasks.indexWhere((t) => t.id == taskId);
    if (i == -1) return;
    final now = AppClock.now();
    tasks[i] = tasks[i].copyWith(
      done: true,
      doneAt: '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
    );
  }

  /// Clears everything — used by the empty-state demo and on sign-out.
  @action
  void clear() {
    plants.clear();
    tasks.clear();
    state = LoadState.empty;
  }
}
