// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plantdex_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$PlantdexStore on _PlantdexStore, Store {
  Computed<bool>? _$isLoadingComputed;

  @override
  bool get isLoading => (_$isLoadingComputed ??= Computed<bool>(
    () => super.isLoading,
    name: '_PlantdexStore.isLoading',
  )).value;
  Computed<int>? _$catalogueSizeComputed;

  @override
  int get catalogueSize => (_$catalogueSizeComputed ??= Computed<int>(
    () => super.catalogueSize,
    name: '_PlantdexStore.catalogueSize',
  )).value;
  Computed<PlantSpecies>? _$plantOfTheWeekComputed;

  @override
  PlantSpecies get plantOfTheWeek =>
      (_$plantOfTheWeekComputed ??= Computed<PlantSpecies>(
        () => super.plantOfTheWeek,
        name: '_PlantdexStore.plantOfTheWeek',
      )).value;
  Computed<List<PlantSpecies>>? _$filteredSpeciesComputed;

  @override
  List<PlantSpecies> get filteredSpecies =>
      (_$filteredSpeciesComputed ??= Computed<List<PlantSpecies>>(
        () => super.filteredSpecies,
        name: '_PlantdexStore.filteredSpecies',
      )).value;
  Computed<bool>? _$hasQueryComputed;

  @override
  bool get hasQuery => (_$hasQueryComputed ??= Computed<bool>(
    () => super.hasQuery,
    name: '_PlantdexStore.hasQuery',
  )).value;
  Computed<String>? _$resultsLabelComputed;

  @override
  String get resultsLabel => (_$resultsLabelComputed ??= Computed<String>(
    () => super.resultsLabel,
    name: '_PlantdexStore.resultsLabel',
  )).value;
  Computed<bool>? _$isEmptyComputed;

  @override
  bool get isEmpty => (_$isEmptyComputed ??= Computed<bool>(
    () => super.isEmpty,
    name: '_PlantdexStore.isEmpty',
  )).value;

  late final _$speciesAtom = Atom(
    name: '_PlantdexStore.species',
    context: context,
  );

  @override
  ObservableList<PlantSpecies> get species {
    _$speciesAtom.reportRead();
    return super.species;
  }

  @override
  set species(ObservableList<PlantSpecies> value) {
    _$speciesAtom.reportWrite(value, super.species, () {
      super.species = value;
    });
  }

  late final _$stateAtom = Atom(name: '_PlantdexStore.state', context: context);

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
    name: '_PlantdexStore.errorMessage',
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
    name: '_PlantdexStore.searchQuery',
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

  late final _$selectedFiltersAtom = Atom(
    name: '_PlantdexStore.selectedFilters',
    context: context,
  );

  @override
  ObservableSet<PlantdexFilter> get selectedFilters {
    _$selectedFiltersAtom.reportRead();
    return super.selectedFilters;
  }

  @override
  set selectedFilters(ObservableSet<PlantdexFilter> value) {
    _$selectedFiltersAtom.reportWrite(value, super.selectedFilters, () {
      super.selectedFilters = value;
    });
  }

  late final _$loadPlantdexAsyncAction = AsyncAction(
    '_PlantdexStore.loadPlantdex',
    context: context,
  );

  @override
  Future<void> loadPlantdex({bool force = false}) {
    return _$loadPlantdexAsyncAction.run(
      () => super.loadPlantdex(force: force),
    );
  }

  late final _$_PlantdexStoreActionController = ActionController(
    name: '_PlantdexStore',
    context: context,
  );

  @override
  void setSearchQuery(String value) {
    final _$actionInfo = _$_PlantdexStoreActionController.startAction(
      name: '_PlantdexStore.setSearchQuery',
    );
    try {
      return super.setSearchQuery(value);
    } finally {
      _$_PlantdexStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleFilter(PlantdexFilter filter) {
    final _$actionInfo = _$_PlantdexStoreActionController.startAction(
      name: '_PlantdexStore.toggleFilter',
    );
    try {
      return super.toggleFilter(filter);
    } finally {
      _$_PlantdexStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearFilters() {
    final _$actionInfo = _$_PlantdexStoreActionController.startAction(
      name: '_PlantdexStore.clearFilters',
    );
    try {
      return super.clearFilters();
    } finally {
      _$_PlantdexStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
species: ${species},
state: ${state},
errorMessage: ${errorMessage},
searchQuery: ${searchQuery},
selectedFilters: ${selectedFilters},
isLoading: ${isLoading},
catalogueSize: ${catalogueSize},
plantOfTheWeek: ${plantOfTheWeek},
filteredSpecies: ${filteredSpecies},
hasQuery: ${hasQuery},
resultsLabel: ${resultsLabel},
isEmpty: ${isEmpty}
    ''';
  }
}
