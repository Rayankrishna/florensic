import '../models/plant_health.dart';
import '../models/plant_species.dart';
import '../provider/species.provider.dart';

/// The result of an identification attempt.
class IdentificationResult {
  const IdentificationResult({
    required this.species,
    required this.scientificName,
    required this.confidence,
    required this.rationale,
    required this.alternatives,
    this.photoId,
    this.initialHealth,
    this.corrected = false,
  });

  /// The species the plant is kept as. One the catalogue does not carry yet
  /// (`species.isListed` false) is still a result, not an error: the name
  /// and confidence stand, only the catalogue entry does not exist yet.
  final PlantSpecies species;

  /// What the model called the plant — the headline when there is no
  /// catalogue row to show.
  final String scientificName;

  /// The uploaded photo this match was made on. Handed to `POST /v1/plants`
  /// when the plant is kept, so it becomes the plant's first photo and its
  /// findings open the first treatment plan.
  final String? photoId;

  /// 0–100.
  final int confidence;

  /// What the match was made on — shown under the confidence bar.
  final String rationale;
  final List<IdentificationAlternative> alternatives;

  /// The scan's own read of the plant's health; null when it gave none.
  final InitialHealth? initialHealth;

  /// True once the keeper picked a different species. The add then sends
  /// `species_id`, which is the correction: the same photo still anchors the
  /// score and findings, the chosen species drives the care plan.
  final bool corrected;

  /// This result, kept as [pick] instead.
  IdentificationResult correctedTo(PlantSpecies pick) => IdentificationResult(
        species: pick,
        scientificName: scientificName,
        confidence: confidence,
        rationale: rationale,
        alternatives: alternatives,
        photoId: photoId,
        initialHealth: initialHealth,
        corrected: true,
      );
}

class IdentificationAlternative {
  const IdentificationAlternative({
    required this.species,
    required this.confidence,
  });

  /// Unlisted (`isListed` false) when the catalogue has no entry: the name
  /// still shows, but it cannot be picked as a correction.
  final PlantSpecies species;
  final int confidence;

  bool get isListed => species.isListed;

  /// `M. adansonii` — genus abbreviated, as the design shows.
  String get shortName {
    final parts = species.latinName.split(' ');
    if (parts.length < 2) return species.latinName;
    return '${parts.first.substring(0, 1)}. ${parts.sublist(1).join(' ')}';
  }
}

/// Plant identification.
///
/// Implementations upload the capture and wait for the analysis job, which
/// is where the recognition actually happens (`POST /v1/photos` then
/// `GET /v1/analysis/{job_id}`).
abstract class IdentificationRepository {
  Future<IdentificationResult> identify({required String framing});

  /// Typeahead for the correction search (`GET /v1/species/suggest`):
  /// scientific and common names, two characters or more.
  Future<List<SpeciesSuggestion>> suggestSpecies(String query);

  /// The species to keep the plant as, from a row the keeper tapped
  /// (`POST /v1/species/resolve`). Answers in well under a second; a species
  /// drafted on the spot has empty care-card fields until a background pass
  /// fills them in.
  Future<PlantSpecies> resolveSpecies(SpeciesSuggestion suggestion);
}

/// Raised when nothing clears the confidence threshold.
class NoConfidentMatch implements Exception {
  const NoConfidentMatch();

  @override
  String toString() => 'No match passed our confidence threshold.';
}
