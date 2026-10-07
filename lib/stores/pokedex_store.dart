import 'package:mobx/mobx.dart';

import '../domain/models/plant_species.dart';
import '../domain/repositories/pokedex_repository.dart';
import '../enum.dart';
import '../interceptors/api_interceptor.dart';
import '../utils/app_log.dart';

part 'pokedex_store.g.dart';

class PokedexStore = _PokedexStore with _$PokedexStore;

abstract class _PokedexStore with Store {
  _PokedexStore(this._repository);

  final PokedexRepository _repository;

  @observable
  ObservableList<PlantSpecies> species = ObservableList<PlantSpecies>();

  @observable
  LoadState state = LoadState.idle;

  @observable
  String? errorMessage;

  @observable
  String searchQuery = '';

  @observable
  ObservableSet<PokedexFilter> selectedFilters = ObservableSet<PokedexFilter>();

  @computed
  bool get isLoading => state == LoadState.loading;

  @computed
  int get catalogueSize => _repository.catalogueSize;

  @computed
  PlantSpecies get plantOfTheWeek => _repository.plantOfTheWeek;

  @computed
  List<PlantSpecies> get filteredSpecies => PokedexQuery.apply(
        species,
        query: searchQuery,
        filters: selectedFilters,
      );

  @computed
  bool get hasQuery => searchQuery.trim().isNotEmpty;

  @computed
  String get resultsLabel {
    final count = filteredSpecies.length;
    if (hasQuery) {
      return '$count result${count == 1 ? '' : 's'} for "${searchQuery.trim()}"';
    }
    if (selectedFilters.isNotEmpty) {
      return '$count match${count == 1 ? '' : 'es'}';
    }
    return '$count species';
  }

  @computed
  bool get isEmpty => state == LoadState.ready && filteredSpecies.isEmpty;

  @action
  void setSearchQuery(String value) => searchQuery = value;

  @action
  void toggleFilter(PokedexFilter filter) {
    if (selectedFilters.contains(filter)) {
      selectedFilters.remove(filter);
    } else {
      selectedFilters.add(filter);
    }
  }

  @action
  void clearFilters() {
    selectedFilters.clear();
    searchQuery = '';
  }

  @action
  Future<void> loadPokedex({bool force = false}) async {
    if (state == LoadState.loading) return;
    if (!force && species.isNotEmpty) return;
    state = LoadState.loading;
    errorMessage = null;

    List<PlantSpecies> resp;
    try {
      resp = await _repository.loadCatalogue();
    } catch (e, stack) {
      AppLog.e('loading the catalogue failed',
          name: 'pokedex', error: e, stackTrace: stack);
      runInAction(() {
        errorMessage = e is ApiException ? e.message : e.toString();
        if (species.isEmpty) state = LoadState.error;
      });
      return;
    }

    AppLog.i('loaded ${resp.length} species', name: 'pokedex');
    runInAction(() {
      species = ObservableList<PlantSpecies>.of(resp);
      state = LoadState.ready;
    });
  }

  PlantSpecies? speciesById(String id) {
    for (final s in species) {
      if (s.id == id) return s;
    }
    return null;
  }
}
