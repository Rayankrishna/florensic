import '../../../interceptors/api_interceptor.dart';
import '../../../shared/services/capture_service.dart';
import '../../provider/photos.provider.dart';
import '../identification_repository.dart';

// Providers are injected by name for readable call sites.
// ignore_for_file: prefer_initializing_formals

/// Real `IdentificationRepository`: upload the capture, poll the job, and
/// build the result the scan screen already renders.
class RemoteIdentificationRepository implements IdentificationRepository {
  RemoteIdentificationRepository({PhotosProvider photos = const PhotosProvider()})
      : _photos = photos;

  final PhotosProvider _photos;

  /// The capture to identify. The scanning store sets this immediately
  /// before calling [identify].
  Capture? pendingCapture;

  /// Kept so `POST /v1/plants` can attach the photo that found the plant.
  String? lastPhotoId;

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
    lastPhotoId = queued.photoId;

    final job = await _photos.awaitJob(queued.jobId);
    lastAlternatives = job.alternatives;
    lastInitialHealth = job.initialHealth;

    if (job.isNoMatch || job.species == null) {
      throw const NoConfidentMatch();
    }
    if (job.isFailed) {
      throw ApiException(
        job.error?.isNotEmpty == true
            ? job.error!
            : 'We could not read that photo. Please try again.',
        code: 'analysis_failed',
      );
    }

    return IdentificationResult(
      species: job.species!,
      confidence: job.confidence ?? 0,
      rationale: job.rationale?.isNotEmpty == true
          ? job.rationale!
          : 'Matched against the species catalogue.',
      alternatives: [
        for (final alt in job.alternatives)
          if (alt.species != null)
            IdentificationAlternative(
              species: alt.species!,
              confidence: alt.confidence,
            ),
      ],
    );
  }

  /// The app's `ScanTarget.wholePlant` is `whole_plant` on the wire.
  static String _framing(String target) => switch (target) {
        'wholePlant' => 'whole_plant',
        'flower' => 'flower',
        _ => 'leaf',
      };
}
