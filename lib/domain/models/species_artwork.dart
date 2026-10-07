import '../../enum.dart';

/// Picks the drawn artwork for a species.
///
/// Glyph and ground are frontend-only: the catalogue is a growing, UUID-keyed
/// list, so artwork is chosen by botanical genus with a stable fallback
/// rather than stored per row.
class SpeciesArtwork {
  const SpeciesArtwork._();

  static const Map<String, PlantGlyph> _byGenus = {
    'monstera': PlantGlyph.monstera,
    'rhaphidophora': PlantGlyph.miniMonstera,
    'spathiphyllum': PlantGlyph.peaceLily,
    'dracaena': PlantGlyph.snakePlant,
    'sansevieria': PlantGlyph.snakePlant,
    'chlorophytum': PlantGlyph.snakePlant,
    'ficus': PlantGlyph.fiddleLeaf,
    'strelitzia': PlantGlyph.fiddleLeaf,
    'aloe': PlantGlyph.aloe,
    'curio': PlantGlyph.aloe,
    'senecio': PlantGlyph.aloe,
    'epipremnum': PlantGlyph.pothos,
    'philodendron': PlantGlyph.pothos,
    'pilea': PlantGlyph.pothos,
    'scindapsus': PlantGlyph.pothos,
    'goeppertia': PlantGlyph.calathea,
    'calathea': PlantGlyph.calathea,
    'maranta': PlantGlyph.calathea,
    'zamioculcas': PlantGlyph.zzPlant,
    'crassula': PlantGlyph.zzPlant,
    'peperomia': PlantGlyph.zzPlant,
    'nephrolepis': PlantGlyph.fern,
    'chamaedorea': PlantGlyph.fern,
    'asplenium': PlantGlyph.fern,
    'adiantum': PlantGlyph.fern,
    'howea': PlantGlyph.fern,
  };

  static String _genus(String latinName) {
    final trimmed = latinName.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.split(RegExp(r'\s+')).first.toLowerCase();
  }

  static PlantGlyph glyphFor(String latinName) {
    final match = _byGenus[_genus(latinName)];
    if (match != null) return match;
    // Stable per species so a plant's card never changes shape between runs.
    const values = PlantGlyph.values;
    return values[_genus(latinName).hashCode.abs() % values.length];
  }

  static GroundPalette groundFor(String latinName) =>
      _genus(latinName).hashCode.isEven
          ? GroundPalette.mint
          : GroundPalette.sage;
}
