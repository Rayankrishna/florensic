import '../../enum.dart';
import '../models/plant_species.dart';
import 'mock/mock_api_client.dart';
import 'mock/mock_species.dart';

abstract class PokedexRepository {
  Future<List<PlantSpecies>> loadCatalogue();

  Future<PlantSpecies> speciesById(String id);

  /// Total species in the catalogue, for the header count.
  int get catalogueSize;

  PlantSpecies get plantOfTheWeek;
}

class MockPokedexRepository implements PokedexRepository {
  MockPokedexRepository(this._client);

  final MockApiClient _client;

  @override
  int get catalogueSize => MockSpecies.catalogueSize;

  @override
  PlantSpecies get plantOfTheWeek => MockSpecies.plantOfTheWeek;

  @override
  Future<List<PlantSpecies>> loadCatalogue() => _client.send(
        '/pokedex',
        () => MockSpecies.all,
        failsWhenOffline: false,
      );

  @override
  Future<PlantSpecies> speciesById(String id) => _client.send(
        '/pokedex/$id',
        () => MockSpecies.byId(id),
        failsWhenOffline: false,
      );
}

/// Filter + search, kept out of the store so it can be unit-tested alone.
class PokedexQuery {
  const PokedexQuery._();

  static List<PlantSpecies> apply(
    List<PlantSpecies> source, {
    required String query,
    required Set<PokedexFilter> filters,
  }) {
    return source
        .where((s) => s.matches(query))
        .where((s) => filters.isEmpty || filters.every(s.traits.contains))
        .toList(growable: false);
  }
}
