import '../../enum.dart';
import '../models/care_task.dart';
import '../models/plant.dart';
import '../models/plant_condition_update.dart';
import '../models/plant_photo.dart';
import '../models/plant_species.dart';
import '../models/treatment.dart';

/// The keeper's collection.
abstract class PlantRepository {
  Future<List<Plant>> loadPlants();

  Future<List<CareTask>> loadTodaysCare();

  Future<Plant> markAsWatered(String plantId);

  /// `soil_wet` counts as care given and moves the next watering out two
  /// days; `away` and `forgot` only record that it was not done.
  Future<Plant> skipWatering(String plantId, WateringSkipReason reason);

  /// What the keeper can tell us without a photo. Pulls the next check-in
  /// window forward; never moves the health score.
  Future<Plant> addNote(String plantId, List<NoteChip> chips, {String? text});

  Future<CheckInResult> submitConditionUpdate(
    String plantId, {
    required ConditionVerdict verdict,
    required List<String> observations,
    required String note,
  });

  /// Paused plants only; a stale plant comes back through a check-in.
  Future<Plant> resumeActiveCare(String plantId);

  /// The plant's photos, newest first. Detail and gallery screens only; a
  /// list uses the plant's `coverPhoto`.
  Future<List<PlantPhoto>> loadPhotos(String plantId);

  /// The per-problem rows. Kept for "has this plant had thrips before?".
  Future<List<Treatment>> loadTreatments(String plantId);

  /// The plans: one per plant at a time, problems grouped, steps in order.
  Future<List<Course>> loadCourses(String plantId);

  /// Stops one problem's course.
  Future<Treatment> abandonTreatment(String treatmentId, AbandonReason reason,
      {String? note});

  /// Stops every open problem on a plan in one go.
  Future<Course> abandonCourse(String courseId, AbandonReason reason,
      {String? note});

  /// Adds [species] to the collection. [nickname] is what the keeper calls
  /// this particular plant; blank falls back to the species' common name.
  Future<Plant> addPlant(PlantSpecies species, {String? nickname});

  Future<void> removePlant(String plantId);

  Future<Plant> setReminder(String plantId,
      {bool? watering, bool? checkIn});

  Future<void> completeTask(String taskId);

  /// Treatment steps only.
  Future<void> skipTask(String taskId, {String? reason});
}

/// What a finished check-in hands back.
class CheckInResult {
  const CheckInResult({
    required this.plant,
    this.update,
    this.nextCheckIn,
  });

  /// The rebuilt plant, carrying `risk`.
  final Plant plant;

  /// Null when the job landed without a readable update payload.
  final ConditionUpdate? update;
  final DateTime? nextCheckIn;
}

enum WateringSkipReason {
  soilWet('soil_wet', 'Soil is still wet', 'Next watering moves out two days'),
  away('away', 'I am away', 'The watering stays due'),
  forgot('forgot', 'I forgot', 'The watering stays due');

  const WateringSkipReason(this.wire, this.label, this.detail);

  final String wire;
  final String label;
  final String detail;
}

/// The quick-note vocabulary. The server rejects anything else.
enum NoteChip {
  drooping('drooping', 'Drooping'),
  drySoil('dry_soil', 'Dry soil'),
  wetSoil('wet_soil', 'Wet soil'),
  yellowing('yellowing', 'Yellowing'),
  leafDrop('leaf_drop', 'Leaf drop'),
  pestsSeen('pests_seen', 'Pests seen'),
  newGrowth('new_growth', 'New growth');

  const NoteChip(this.wire, this.label);

  final String wire;
  final String label;
}
