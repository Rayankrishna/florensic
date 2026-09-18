import 'package:mobx/mobx.dart';

import '../domain/models/care_task.dart';
import '../domain/models/plant.dart';
import '../domain/models/plant_species.dart';
import '../domain/repositories/plant_repository.dart';
import '../enum.dart';
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

  @computed
  int get averageHealth {
    final scored = plants.where((p) => p.healthScore != null).toList();
    if (scored.isEmpty) return 0;
    final total = scored.fold<int>(0, (sum, p) => sum + p.healthScore!);
    return (total / scored.length).round();
  }

  @computed
  int get underActiveCare => plants.where((p) => !p.paused).length;

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
    try {
      final result = await _repository.loadPlants();
      final todays = await _repository.loadTodaysCare();
      plants = ObservableList<Plant>.of(result);
      tasks = ObservableList<CareTask>.of(todays);
      state = plants.isEmpty ? LoadState.empty : LoadState.ready;
    } catch (e) {
      errorMessage = e.toString();
      state = LoadState.error;
    }
  }

  @action
  void replacePlant(Plant plant) {
    final i = plants.indexWhere((p) => p.id == plant.id);
    if (i == -1) return;
    plants[i] = plant;
  }

  @action
  Future<Plant?> markAsWatered(String plantId) async {
    busyPlantId = plantId;
    try {
      final updated = await _repository.markAsWatered(plantId);
      replacePlant(updated);
      _completeLocalTask('task-water-$plantId');
      return updated;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      busyPlantId = null;
    }
  }

  @action
  Future<Plant?> addPlant(PlantSpecies species, {String? nickname}) async {
    try {
      final plant = await _repository.addPlant(species, nickname: nickname);
      plants.insert(0, plant);
      state = LoadState.ready;
      return plant;
    } catch (e) {
      errorMessage = e.toString();
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
    } catch (e) {
      // Put it back if the delete failed.
      plants.addAll(removed);
      state = plants.isEmpty ? LoadState.empty : LoadState.ready;
      errorMessage = e.toString();
    }
  }

  @action
  Future<void> completeTask(String taskId) async {
    _completeLocalTask(taskId);
    await _repository.completeTask(taskId);
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
