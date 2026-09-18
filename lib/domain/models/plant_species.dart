import '../../enum.dart';

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
  });

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

  /// Compact chips on the grid card: difficulty + a light hint.
  String get shortLight {
    final word = light.split(' ').last;
    return word[0].toUpperCase() + word.substring(1);
  }

  /// Default watering cadence in days, parsed from [water].
  int get wateringIntervalDays {
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

  final String title;
  final String body;
  final MetricStatus tone;
}
