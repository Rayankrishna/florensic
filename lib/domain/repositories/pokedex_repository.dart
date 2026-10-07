import '../../enum.dart';
import '../models/plant_species.dart';

abstract class PokedexRepository {
  Future<List<PlantSpecies>> loadCatalogue();

  Future<PlantSpecies> speciesById(String id);

  /// Total species in the catalogue, for the header count.
  int get catalogueSize;

  PlantSpecies get plantOfTheWeek;
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
