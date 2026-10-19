import '../../../enum.dart';
import '../../../interceptors/api_interceptor.dart';
import '../../models/care_task.dart';
import '../../models/plant.dart';
import '../../models/plant_photo.dart';
import '../../models/plant_setup.dart';
import '../../models/treatment.dart';
import '../../provider/photos.provider.dart';
import '../../provider/plants.provider.dart';
import '../plant_repository.dart';

// Providers are injected by name for readable call sites.
// ignore_for_file: prefer_initializing_formals

/// Real `PlantRepository`.
///
/// Every mutation returns the complete plant, so the stores keep calling
/// `replacePlant` on the result of every call.
class RemotePlantRepository implements PlantRepository {
  RemotePlantRepository({
    PlantsProvider plants = const PlantsProvider(),
    PhotosProvider photos = const PhotosProvider(),
  })  : _plants = plants,
        _photos = photos;

  final PlantsProvider _plants;
  final PhotosProvider _photos;

  /// Set by the check-in flow before [submitConditionUpdate].
  String? pendingCheckInPhotoId;

  /// Mirrors the "keep the photos in my library" toggle on the remove sheet.
  bool keepPhotosOnRemove = false;

  @override
  Future<List<Plant>> loadPlants() => _plants.list();

  @override
  Future<List<CareTask>> loadTodaysCare() => _plants.todaysCare();

  @override
  Future<Plant> markAsWatered(String plantId) => _plants.water(plantId);

  @override
  Future<Plant> skipWatering(String plantId, WateringSkipReason reason) =>
      _plants.skipWatering(plantId, reason.wire);

  @override
  Future<Plant> addNote(String plantId, List<NoteChip> chips,
          {String? text}) =>
      _plants.addNote(plantId, [for (final c in chips) c.wire], text: text);

  @override
  Future<Plant> resumeActiveCare(String plantId) => _plants.resume(plantId);

  @override
  Future<List<PlantPhoto>> loadPhotos(String plantId) =>
      _photos.forPlant(plantId);

  @override
  Future<List<Treatment>> loadTreatments(String plantId) =>
      _plants.treatments(plantId);

  @override
  Future<List<Course>> loadCourses(String plantId) => _plants.courses(plantId);

  @override
  Future<Treatment> abandonTreatment(String treatmentId, AbandonReason reason,
          {String? note}) =>
      _plants.abandonTreatment(treatmentId, reason.wire, note: note);

  @override
  Future<Course> abandonCourse(String courseId, AbandonReason reason,
          {String? note}) =>
      _plants.abandonCourse(courseId, reason.wire, note: note);

  /// Answers in about a second with the plant's database half — species,
  /// score, findings, cover — and a `setup` block; the treatment course and
  /// the first care plan are drafted behind it (see [loadSetup]). A photo
  /// whose identification has not finished answers
  /// `identification_not_ready`; that one is polled a few times before it is
  /// given up on, since the job is seconds from done.
  @override
  Future<Plant> addPlant({
    required String photoId,
    String? speciesId,
    String? nickname,
  }) async {
    for (var attempt = 0;; attempt++) {
      try {
        return await _plants.create(
          photoId: photoId,
          speciesId: speciesId,
          nickname: nickname,
        );
      } on ApiException catch (e) {
        if (!e.isIdentificationNotReady || attempt >= _notReadyRetries) {
          rethrow;
        }
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  static const int _notReadyRetries = 10;

  @override
  Future<PlantSetup> loadSetup(String plantId) => _plants.setup(plantId);

  @override
  Future<void> removePlant(String plantId) =>
      _plants.remove(plantId, keepPhotos: keepPhotosOnRemove);

  @override
  Future<Plant> setReminder(String plantId, {bool? watering, bool? checkIn}) =>
      _plants.updateSchedule(plantId, {
        'watering_reminder': ?watering,
        'check_in_reminder': ?checkIn,
      });

  @override
  Future<void> completeTask(String taskId) => _plants.completeTask(taskId);

  @override
  Future<void> skipTask(String taskId, {String? reason}) =>
      _plants.skipTask(taskId, reason: reason);

  /// Submits the check-in and waits for the analysis to land, returning the
  /// plant the server rebuilt (§3.4).
  @override
  Future<CheckInResult> submitConditionUpdate(
    String plantId, {
    required ConditionVerdict verdict,
    required List<String> observations,
    required String note,
    void Function(JobStage stage)? onProgress,
  }) async {
    final photoId = pendingCheckInPhotoId;
    if (photoId == null) {
      throw const ApiException(
        'Add a photo before saving this check-in.',
        code: 'photo_required',
      );
    }
    final jobId = await _plants.submitConditionUpdate(
      plantId,
      photoId: photoId,
      userVerdict: _verdictName(verdict),
      observations: observations,
      note: note,
    );
    pendingCheckInPhotoId = null;

    final job = await _photos.awaitJob(
      jobId,
      onTick: (current) {
        final stage = current.progress.lastOrNull;
        if (stage != null) onProgress?.call(stage);
      },
    );
    if (job.isFailed) {
      throw ApiException(
        job.error?.isNotEmpty == true
            ? job.error!
            : 'We could not read that photo. Please try again.',
        code: 'analysis_failed',
      );
    }
    final plant = job.checkinPlant;
    // The check-in photo becomes the cover; if the payload predates that,
    // re-read the plant so screens don't keep the old (or no) picture.
    if (plant != null && plant.coverPhoto?.photoId == photoId) {
      return CheckInResult(
        plant: plant,
        update: job.checkinUpdate,
        nextCheckIn: job.nextCheckIn,
      );
    }
    // The check-in landed but the payload was thin or stale — re-read the
    // plant so the UI still shows the truth.
    return CheckInResult(
      plant: await _plants.byId(plantId),
      update: job.checkinUpdate,
      nextCheckIn: job.nextCheckIn,
    );
  }

  static String _verdictName(ConditionVerdict verdict) => switch (verdict) {
        ConditionVerdict.healthy => 'healthy',
        ConditionVerdict.concerns => 'concerns',
        ConditionVerdict.needsAttention => 'needs_attention',
      };
}
