import '../../../interceptors/api_interceptor.dart';
import '../../../shared/services/capture_service.dart';
import '../../../utils/app_log.dart';
import '../../models/plant_health.dart';
import '../../models/plant_species.dart';
import '../../provider/photos.provider.dart';
import '../../provider/species.provider.dart';
import '../identification_repository.dart';

// Providers are injected by name for readable call sites.
// ignore_for_file: prefer_initializing_formals

/// Real `IdentificationRepository`: upload the capture, poll the job, and
/// build the result the scan screen already renders.
class RemoteIdentificationRepository implements IdentificationRepository {
  RemoteIdentificationRepository({
    PhotosProvider photos = const PhotosProvider(),
    SpeciesProvider species = const SpeciesProvider(),
  })  : _photos = photos,
        _species = species;

  final PhotosProvider _photos;
  final SpeciesProvider _species;

  /// The capture to identify. The scanning store sets this immediately
  /// before calling [identify].
  Capture? pendingCapture;

  /// Populated on a no-match so the result sheet can still offer the
  /// runners-up and the manual search.
  List<AnalysisAlternative> lastAlternatives = const [];

  /// The model's first read of the plant's health, shown on the result card.
  Map<String, dynamic>? lastInitialHealth;

  @override
  Future<IdentificationResult> identify({required String framing}) async {
    final capture = pendingCapture;
    if (capture == null) {
      throw const ApiException(
        'Take a photo to identify a plant.',
        code: 'photo_required',
      );
    }

    final queued = await _photos.upload(
      filePath: capture.path,
      purpose: PhotoPurpose.identify,
      framing: _framing(framing),
      source: capture.source,
      lat: capture.lat,
      lon: capture.lon,
      locationAccuracyM: capture.accuracyM,
      capturedAt: capture.capturedAt,
    );
    final job = await _photos.awaitJob(queued.jobId);
    lastAlternatives = job.alternatives;
    lastInitialHealth = job.initialHealth;

    if (job.isFailed) {
      throw ApiException(
        job.error?.isNotEmpty == true
            ? job.error!
            : 'We could not read that photo. Please try again.',
        code: 'analysis_failed',
      );
    }
    // Switched off server-side, kept because one env value brings it back.
    if (job.isNoMatch) throw const NoConfidentMatch();

    // A null species on a finished job is a plant the catalogue does not
    // carry yet, not a failure: the name and confidence stand.
    return IdentificationResult(
      species: job.species ?? PlantSpecies.unlisted(job.scientificName),
      scientificName: job.scientificName,
      photoId: queued.photoId,
      confidence: job.confidence ?? 0,
      rationale: job.rationale?.isNotEmpty == true
          ? job.rationale!
          : 'Matched against the species catalogue.',
      alternatives: [
        for (final alt in job.alternatives)
          IdentificationAlternative(
            species:
                alt.species ?? PlantSpecies.unlisted(alt.scientificName),
            confidence: alt.confidence,
          ),
      ],
      initialHealth: InitialHealth.fromJson(job.initialHealth),
    );
  }

  @override
  Future<List<SpeciesSuggestion>> suggestSpecies(String query) =>
      _species.suggest(query);

  @override
  Future<PlantSpecies> resolveSpecies(SpeciesSuggestion suggestion) async {
    final id = await _species.resolve(suggestion);
    try {
      return await _species.byId(id);
    } on ApiException catch (e) {
      // Just drafted, and its card may not be readable yet. The id and name
      // are all the add needs; the server fills the rest in behind it.
      AppLog.w('species $id not readable after resolve: ${e.code}',
          name: 'scan');
      return PlantSpecies.unlisted(suggestion.scientificName, id: id);
    }
  }

  /// The app's `ScanTarget.wholePlant` is `whole_plant` on the wire.
  static String _framing(String target) => switch (target) {
        'wholePlant' => 'whole_plant',
        'flower' => 'flower',
        _ => 'leaf',
      };
}
