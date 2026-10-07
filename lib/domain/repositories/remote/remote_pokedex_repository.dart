import '../../models/plant_species.dart';
import '../../provider/species.provider.dart';
import '../pokedex_repository.dart';

// Providers are injected by name for readable call sites.
// ignore_for_file: prefer_initializing_formals

/// Real `PokedexRepository`.
///
/// The catalogue is paged and growing, so `catalogueSize` and
/// `plantOfTheWeek` are filled by the first load and read synchronously
/// afterwards, which keeps the store's interface unchanged.
class RemotePokedexRepository implements PokedexRepository {
  RemotePokedexRepository({SpeciesProvider provider = const SpeciesProvider()})
      : _provider = provider;

  final SpeciesProvider _provider;

  int _total = 0;
  PlantSpecies? _featured;
  List<PlantSpecies> _cached = const [];

  @override
  int get catalogueSize => _total;

  @override
  PlantSpecies get plantOfTheWeek =>
      _featured ?? (_cached.isNotEmpty ? _cached.first : _placeholder);

  @override
  Future<List<PlantSpecies>> loadCatalogue() async {
    final page = await _provider.catalogue();
    _total = page.total;
    _cached = page.items;
    // The feature is decorative — a failure must not empty the catalogue.
    try {
      _featured = await _provider.featured();
    } catch (_) {
      _featured = page.items.isNotEmpty ? page.items.first : null;
    }
    return page.items;
  }

  /// Loads the next page; returns an empty list when the catalogue is done.
  Future<List<PlantSpecies>> loadMore(String? cursor) async {
    if (cursor == null) return const [];
    final page = await _provider.catalogue(cursor: cursor);
    _cached = [..._cached, ...page.items];
    return page.items;
  }

  @override
  Future<PlantSpecies> speciesById(String id) => _provider.byId(id);

  static final PlantSpecies _placeholder = PlantSpecies(
    id: '',
    number: 0,
    commonName: 'Loading…',
    latinName: '',
    glyph: PlantSpecies.fromJson(const {}).glyph,
    ground: PlantSpecies.fromJson(const {}).ground,
    summary: '',
    difficulty: 'Easy',
    light: '',
    water: '',
    temperature: '',
    humidity: '',
    nativeRange: '',
    matureHeight: '',
    growthHabit: '',
    tags: const [],
    traits: const {},
    commonIssues: const [],
    careTips: const [],
  );
}
