import '../models/plant_species.dart';

/// The result of an identification attempt.
class IdentificationResult {
  const IdentificationResult({
    required this.species,
    required this.confidence,
    required this.rationale,
    required this.alternatives,
  });

  final PlantSpecies species;

  /// 0–100.
  final int confidence;

  /// What the match was made on — shown under the confidence bar.
  final String rationale;
  final List<IdentificationAlternative> alternatives;
}

class IdentificationAlternative {
  const IdentificationAlternative({
    required this.species,
    required this.confidence,
  });

  final PlantSpecies species;
  final int confidence;

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
}

/// Raised when nothing clears the confidence threshold.
class NoConfidentMatch implements Exception {
  const NoConfidentMatch();

  @override
  String toString() => 'No match passed our confidence threshold.';
}
