// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plant_collection_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$PlantCollectionStore on _PlantCollectionStore, Store {
  Computed<bool>? _$isLoadingComputed;

  @override
  bool get isLoading => (_$isLoadingComputed ??= Computed<bool>(
    () => super.isLoading,
    name: '_PlantCollectionStore.isLoading',
  )).value;
  Computed<bool>? _$isEmptyComputed;

  @override
  bool get isEmpty => (_$isEmptyComputed ??= Computed<bool>(
    () => super.isEmpty,
    name: '_PlantCollectionStore.isEmpty',
  )).value;
  Computed<List<Plant>>? _$filteredPlantsComputed;

  @override
  List<Plant> get filteredPlants =>
      (_$filteredPlantsComputed ??= Computed<List<Plant>>(
        () => super.filteredPlants,
        name: '_PlantCollectionStore.filteredPlants',
      )).value;
  Computed<List<Plant>>? _$needsAttentionComputed;

  @override
  List<Plant> get needsAttention =>
      (_$needsAttentionComputed ??= Computed<List<Plant>>(
        () => super.needsAttention,
        name: '_PlantCollectionStore.needsAttention',
      )).value;
  Computed<int>? _$attentionCountComputed;

  @override
  int get attentionCount => (_$attentionCountComputed ??= Computed<int>(
    () => super.attentionCount,
    name: '_PlantCollectionStore.attentionCount',
  )).value;
  Computed<List<CareTask>>? _$openTasksComputed;

  @override
  List<CareTask> get openTasks =>
      (_$openTasksComputed ??= Computed<List<CareTask>>(
        () => super.openTasks,
        name: '_PlantCollectionStore.openTasks',
      )).value;
  Computed<int>? _$doneTaskCountComputed;

  @override
  int get doneTaskCount => (_$doneTaskCountComputed ??= Computed<int>(
    () => super.doneTaskCount,
    name: '_PlantCollectionStore.doneTaskCount',
  )).value;
  Computed<bool>? _$allCaughtUpComputed;

  @override
  bool get allCaughtUp => (_$allCaughtUpComputed ??= Computed<bool>(
    () => super.allCaughtUp,
    name: '_PlantCollectionStore.allCaughtUp',
  )).value;
  Computed<List<Plant>>? _$recentlyAddedComputed;

  @override
  List<Plant> get recentlyAdded =>
      (_$recentlyAddedComputed ??= Computed<List<Plant>>(
        () => super.recentlyAdded,
        name: '_PlantCollectionStore.recentlyAdded',
      )).value;
  Computed<int>? _$averageHealthComputed;

  @override
  int get averageHealth => (_$averageHealthComputed ??= Computed<int>(
    () => super.averageHealth,
    name: '_PlantCollectionStore.averageHealth',
  )).value;
  Computed<int>? _$underActiveCareComputed;

  @override
  int get underActiveCare => (_$underActiveCareComputed ??= Computed<int>(
    () => super.underActiveCare,
    name: '_PlantCollectionStore.underActiveCare',
  )).value;

  late final _$plantsAtom = Atom(
    name: '_PlantCollectionStore.plants',
    context: context,
  );

  @override
  ObservableList<Plant> get plants {
    _$plantsAtom.reportRead();
    return super.plants;
  }

  @override
  set plants(ObservableList<Plant> value) {
    _$plantsAtom.reportWrite(value, super.plants, () {
      super.plants = value;
    });
  }

  late final _$tasksAtom = Atom(
    name: '_PlantCollectionStore.tasks',
    context: context,
  );

  @override
  ObservableList<CareTask> get tasks {
    _$tasksAtom.reportRead();
    return super.tasks;
  }

  @override
  set tasks(ObservableList<CareTask> value) {
    _$tasksAtom.reportWrite(value, super.tasks, () {
      super.tasks = value;
    });
  }

  late final _$stateAtom = Atom(
    name: '_PlantCollectionStore.state',
    context: context,
  );

  @override
  LoadState get state {
    _$stateAtom.reportRead();
    return super.state;
  }

  @override
  set state(LoadState value) {
    _$stateAtom.reportWrite(value, super.state, () {
      super.state = value;
    });
  }

  late final _$errorMessageAtom = Atom(
    name: '_PlantCollectionStore.errorMessage',
    context: context,
  );

  @override
  String? get errorMessage {
    _$errorMessageAtom.reportRead();
    return super.errorMessage;
  }

  @override
  set errorMessage(String? value) {
    _$errorMessageAtom.reportWrite(value, super.errorMessage, () {
      super.errorMessage = value;
    });
  }

  late final _$searchQueryAtom = Atom(
    name: '_PlantCollectionStore.searchQuery',
    context: context,
  );

  @override
  String get searchQuery {
    _$searchQueryAtom.reportRead();
    return super.searchQuery;
  }

  @override
  set searchQuery(String value) {
    _$searchQueryAtom.reportWrite(value, super.searchQuery, () {
      super.searchQuery = value;
    });
  }

  late final _$selectedFilterAtom = Atom(
    name: '_PlantCollectionStore.selectedFilter',
    context: context,
  );

  @override
  PlantFilter get selectedFilter {
    _$selectedFilterAtom.reportRead();
    return super.selectedFilter;
  }

  @override
  set selectedFilter(PlantFilter value) {
    _$selectedFilterAtom.reportWrite(value, super.selectedFilter, () {
      super.selectedFilter = value;
    });
  }

  late final _$busyPlantIdAtom = Atom(
    name: '_PlantCollectionStore.busyPlantId',
    context: context,
  );

  @override
  String? get busyPlantId {
    _$busyPlantIdAtom.reportRead();
    return super.busyPlantId;
  }

  @override
  set busyPlantId(String? value) {
    _$busyPlantIdAtom.reportWrite(value, super.busyPlantId, () {
      super.busyPlantId = value;
    });
  }

  late final _$loadPlantsAsyncAction = AsyncAction(
    '_PlantCollectionStore.loadPlants',
    context: context,
  );

  @override
  Future<void> loadPlants({bool force = false}) {
    return _$loadPlantsAsyncAction.run(() => super.loadPlants(force: force));
  }

  late final _$markAsWateredAsyncAction = AsyncAction(
    '_PlantCollectionStore.markAsWatered',
    context: context,
  );

  @override
  Future<Plant?> markAsWatered(String plantId) {
    return _$markAsWateredAsyncAction.run(() => super.markAsWatered(plantId));
  }

  late final _$addPlantAsyncAction = AsyncAction(
    '_PlantCollectionStore.addPlant',
    context: context,
  );

  @override
  Future<Plant?> addPlant(PlantSpecies species, {String? nickname}) {
    return _$addPlantAsyncAction.run(
      () => super.addPlant(species, nickname: nickname),
    );
  }

  late final _$removePlantAsyncAction = AsyncAction(
    '_PlantCollectionStore.removePlant',
    context: context,
  );

  @override
  Future<void> removePlant(String plantId) {
    return _$removePlantAsyncAction.run(() => super.removePlant(plantId));
  }

  late final _$completeTaskAsyncAction = AsyncAction(
    '_PlantCollectionStore.completeTask',
    context: context,
  );

  @override
  Future<void> completeTask(String taskId) {
    return _$completeTaskAsyncAction.run(() => super.completeTask(taskId));
  }

  late final _$_PlantCollectionStoreActionController = ActionController(
    name: '_PlantCollectionStore',
    context: context,
  );

  @override
  void setSearchQuery(String value) {
    final _$actionInfo = _$_PlantCollectionStoreActionController.startAction(
      name: '_PlantCollectionStore.setSearchQuery',
    );
    try {
      return super.setSearchQuery(value);
    } finally {
      _$_PlantCollectionStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setFilter(PlantFilter filter) {
    final _$actionInfo = _$_PlantCollectionStoreActionController.startAction(
      name: '_PlantCollectionStore.setFilter',
    );
    try {
      return super.setFilter(filter);
    } finally {
      _$_PlantCollectionStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void replacePlant(Plant plant) {
    final _$actionInfo = _$_PlantCollectionStoreActionController.startAction(
      name: '_PlantCollectionStore.replacePlant',
    );
    try {
      return super.replacePlant(plant);
    } finally {
      _$_PlantCollectionStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clear() {
    final _$actionInfo = _$_PlantCollectionStoreActionController.startAction(
      name: '_PlantCollectionStore.clear',
    );
    try {
      return super.clear();
    } finally {
      _$_PlantCollectionStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
plants: ${plants},
tasks: ${tasks},
state: ${state},
errorMessage: ${errorMessage},
searchQuery: ${searchQuery},
selectedFilter: ${selectedFilter},
busyPlantId: ${busyPlantId},
isLoading: ${isLoading},
isEmpty: ${isEmpty},
filteredPlants: ${filteredPlants},
needsAttention: ${needsAttention},
attentionCount: ${attentionCount},
openTasks: ${openTasks},
doneTaskCount: ${doneTaskCount},
allCaughtUp: ${allCaughtUp},
recentlyAdded: ${recentlyAdded},
averageHealth: ${averageHealth},
underActiveCare: ${underActiveCare}
    ''';
  }
}
