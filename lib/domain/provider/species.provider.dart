import '../core/json.dart';
import '../core/services_config.dart';
import '../models/plant_species.dart';

/// One page of the catalogue.
class SpeciesPage {
  const SpeciesPage({
    required this.items,
    required this.total,
    required this.nextCursor,
  });

  final List<PlantSpecies> items;
  final int total;
  final String? nextCursor;
}

/// A typeahead row: either a catalogue species or an iNaturalist match that
/// must be resolved before it can be used.
class SpeciesSuggestion {
  const SpeciesSuggestion({
    required this.source,
    required this.speciesId,
    required this.externalId,
    required this.scientificName,
    required this.commonName,
    required this.matchedTerm,
  });

  factory SpeciesSuggestion.fromJson(Map<String, dynamic> json) =>
      SpeciesSuggestion(
        source: Json.str(json['source'], 'catalogue'),
        speciesId: json['species_id'] as String?,
        externalId: json['external_id'] as String?,
        scientificName: Json.str(json['scientific_name']),
        commonName: Json.str(json['common_name']),
        matchedTerm: Json.str(json['matched_term']),
      );

  final String source;
  final String? speciesId;
  final String? externalId;
  final String scientificName;
  final String commonName;
  final String matchedTerm;

  /// Catalogue rows are usable immediately; iNaturalist rows need `resolve`.
  bool get isResolved => speciesId != null;

  String get title => commonName.isEmpty ? scientificName : commonName;
}

/// `/v1/species/*`.
class SpeciesProvider {
  const SpeciesProvider();

  HttpClient get _http => http!;

  Future<SpeciesPage> catalogue({
    int limit = 100,
    String? cursor,
    String? query,
    List<String> traits = const [],
  }) =>
      _http.get(
        '/species',
        (json) {
          final map = Json.map(json);
          return SpeciesPage(
            items: Json.list(map['items']).map(PlantSpecies.fromJson).toList(),
            total: Json.integer(map['total']),
            nextCursor: map['next_cursor'] as String?,
          );
        },
        query: {
          'limit': limit,
          'cursor': ?cursor,
          if (query != null && query.isNotEmpty) 'q': query,
          if (traits.isNotEmpty) 'traits': traits.join(','),
        },
        auth: false,
      );

  Future<PlantSpecies> byId(String id) => _http.get(
        '/species/$id',
        (json) => PlantSpecies.fromJson(Json.map(json)),
        auth: false,
      );

  Future<PlantSpecies> featured() => _http.get(
        '/species/featured',
        (json) => PlantSpecies.fromJson(Json.map(json)),
        auth: false,
      );

  /// Public typeahead — debounce ~300 ms, minimum two characters.
  Future<List<SpeciesSuggestion>> suggest(String query, {int limit = 8}) =>
      _http.get(
        '/species/suggest',
        (json) => Json.list(Json.map(json)['items'])
            .map(SpeciesSuggestion.fromJson)
            .toList(),
        query: {'q': query, 'limit': limit},
        auth: false,
      );

  /// Turns an unresolved suggestion into a catalogue species id. A brand new
  /// plant takes ~10 s while its care baseline is drafted.
  Future<String> resolve(SpeciesSuggestion suggestion) => _http.post(
        '/species/resolve',
        (json) => Json.str(Json.map(json)['species_id']),
        body: {
          'source': suggestion.source,
          if (suggestion.speciesId != null) 'species_id': suggestion.speciesId,
          if (suggestion.externalId != null)
            'external_id': suggestion.externalId,
          'scientific_name': suggestion.scientificName,
          if (suggestion.matchedTerm.isNotEmpty)
            'matched_term': suggestion.matchedTerm,
        },
      );
}
