import '../models/plant_species.dart';
import 'mock/mock_api_client.dart';
import 'mock/mock_species.dart';

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
/// No image recognition runs here. The mock returns a scripted match so the
/// flow, its confidence display and its failure states can be exercised;
/// wire a real vision service into a second implementation.
abstract class IdentificationRepository {
  Future<IdentificationResult> identify({required String framing});

  /// Forces the next [identify] call to fail with no confident match.
  set alwaysFail(bool value);
}

class MockIdentificationRepository implements IdentificationRepository {
  MockIdentificationRepository(this._client);

  final MockApiClient _client;

  bool _alwaysFail = false;

  @override
  set alwaysFail(bool value) => _alwaysFail = value;

  @override
  Future<IdentificationResult> identify({required String framing}) =>
      _client.send(
        '/identify',
        () {
          if (_alwaysFail) {
            throw const NoConfidentMatch();
          }
          return IdentificationResult(
            species: MockSpecies.byId('monstera-deliciosa'),
            // The scripted match reports the specification's own confidence.
            confidence: 94,
            rationale:
                'Matched on leaf shape, fenestration pattern and petiole angle.',
            alternatives: [
              IdentificationAlternative(
                species: MockSpecies.byId('monstera-adansonii'),
                confidence: 71,
              ),
              IdentificationAlternative(
                species: MockSpecies.byId('rhaphidophora-tetrasperma'),
                confidence: 63,
              ),
            ],
          );
        },
        params: {'framing': framing},
      );
}

/// Raised when nothing clears the confidence threshold.
class NoConfidentMatch implements Exception {
  const NoConfidentMatch();

  @override
  String toString() => 'No match passed our confidence threshold.';
}
