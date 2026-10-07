import '../../enum.dart';
import '../core/json.dart';
import 'species_artwork.dart';

/// A Pokedex entry — the reference record for a species.
class PlantSpecies {
  const PlantSpecies({
    required this.id,
    required this.number,
    required this.commonName,
    required this.latinName,
    required this.glyph,
    required this.ground,
    required this.summary,
    required this.difficulty,
    required this.light,
    required this.water,
    required this.temperature,
    required this.humidity,
    required this.nativeRange,
    required this.matureHeight,
    required this.growthHabit,
    required this.tags,
    required this.traits,
    required this.commonIssues,
    required this.careTips,
    this.tagline,
    this.imageUrl,
    this.defaultWateringDays,
  });

  /// Builds a species from the catalogue payload.
  ///
  /// `glyph` and `ground` are frontend-only artwork, so they are derived
  /// from the botanical name rather than read from the response (§5).
  factory PlantSpecies.fromJson(Map<String, dynamic> json) {
    final latin = Json.str(json['latin_name']);
    return PlantSpecies(
      id: Json.str(json['id']),
      number: Json.integer(json['number']),
      commonName: Json.str(json['common_name'], latin),
      latinName: latin,
      glyph: SpeciesArtwork.glyphFor(latin),
      ground: SpeciesArtwork.groundFor(latin),
      summary: Json.str(json['summary']),
      difficulty: Json.str(json['difficulty'], 'Easy'),
      light: Json.str(json['light'], 'Bright indirect'),
      water: Json.str(json['water'], 'Every 7 days'),
      temperature: Json.str(json['temperature']),
      humidity: Json.str(json['humidity']),
      nativeRange: Json.str(json['native_range']),
      matureHeight: Json.str(json['mature_height']),
      growthHabit: Json.str(json['growth_habit']),
      tagline: json['tagline'] is String ? json['tagline'] as String : null,
      tags: Json.list(json['tags']).map(SpeciesTag.fromJson).toList(),
      traits: Json.strings(json['traits'])
          .map(_traitFrom)
          .whereType<PokedexFilter>()
          .toSet(),
      commonIssues:
          Json.list(json['common_issues']).map(SpeciesIssue.fromJson).toList(),
      careTips: Json.strings(json['care_tips']),
      imageUrl: json['image_url'] is String ? json['image_url'] as String : null,
      defaultWateringDays:
          Json.intOrNull(Json.map(json['default_care'])['watering_interval_days']),
    );
  }

  static PokedexFilter? _traitFrom(String raw) => switch (raw) {
        'indoor' => PokedexFilter.indoor,
        'low_light' => PokedexFilter.lowLight,
        'beginner' => PokedexFilter.beginner,
        'pet_friendly' => PokedexFilter.petFriendly,
        _ => null,
      };

  final String id;

  /// Catalogue number, rendered as `№ 014`.
  final int number;
  final String commonName;
  final String latinName;
  final PlantGlyph glyph;
  final GroundPalette ground;
  final String summary;

  /// `Easy` · `Medium` · `Hard`.
  final String difficulty;

  /// Short light label, e.g. `Bright indirect`.
  final String light;

  /// Short watering label, e.g. `Every 7–10 days`.
  final String water;
  final String temperature;
  final String humidity;
  final String nativeRange;
  final String matureHeight;
  final String growthHabit;

  /// Pills under the title, e.g. `Easy care`, `Tropical`, `Toxic to pets`.
  final List<SpeciesTag> tags;

  /// Which discovery filters this species answers to.
  final Set<PokedexFilter> traits;
  final List<SpeciesIssue> commonIssues;
  final List<String> careTips;

  /// One-line hook used by the Plant of the week card.
  final String? tagline;

  /// Photograph from the catalogue, when the backend has one.
  final String? imageUrl;

  /// Server-supplied cadence, preferred over parsing [water].
  final int? defaultWateringDays;

  /// Compact chips on the grid card: difficulty + a light hint.
  String get shortLight {
    final word = light.split(' ').last;
    return word[0].toUpperCase() + word.substring(1);
  }

  /// Default watering cadence in days. The backend's value wins; otherwise
  /// it is read out of the human-readable [water] label.
  int get wateringIntervalDays {
    final supplied = defaultWateringDays;
    if (supplied != null && supplied > 0) return supplied;
    final match = RegExp(r'(\d+)').firstMatch(water);
    return int.tryParse(match?.group(1) ?? '') ?? 7;
  }

  bool matches(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.toLowerCase().trim();
    return commonName.toLowerCase().contains(q) ||
        latinName.toLowerCase().contains(q);
  }
}

/// A pill under the species title. [tone] selects the tint.
class SpeciesTag {
  const SpeciesTag(this.label, this.tone);

  factory SpeciesTag.fromJson(Map<String, dynamic> json) => SpeciesTag(
        Json.str(json['label']),
        Json.enumOf(json['tone'], SpeciesTagTone.values, SpeciesTagTone.neutral),
      );

  final String label;
  final SpeciesTagTone tone;
}

enum SpeciesTagTone { positive, neutral, warning }

/// A known problem plus its remedy.
class SpeciesIssue {
  const SpeciesIssue({
    required this.title,
    required this.body,
    required this.tone,
  });

  factory SpeciesIssue.fromJson(Map<String, dynamic> json) => SpeciesIssue(
        title: Json.str(json['title']),
        body: Json.str(json['body']),
        tone: Json.status(json['tone'], MetricStatus.watch),
      );

  final String title;
  final String body;
  final MetricStatus tone;
}
