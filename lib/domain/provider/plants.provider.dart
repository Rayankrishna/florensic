import '../core/json.dart';
import '../core/services_config.dart';
import '../models/care_task.dart';
import '../models/plant.dart';
import '../models/plant_care_schedule.dart';
import '../models/plant_health.dart';
import '../models/treatment.dart';

/// `/v1/plants/*` and `/v1/care/*`.
class PlantsProvider {
  const PlantsProvider();

  HttpClient get _http => http!;

  static Plant _plant(dynamic json) => Plant.fromJson(Json.map(json));

  Future<List<Plant>> list() => _http.get(
        '/plants',
        (json) => Json.list(json is Map ? json['items'] : json)
            .map(Plant.fromJson)
            .toList(),
      );

  Future<Plant> byId(String id) => _http.get('/plants/$id', _plant);

  Future<Plant> create({
    required String speciesId,
    String? photoId,
    String? nickname,
    String? room,
    bool? indoor,
  }) =>
      _http.post(
        '/plants',
        _plant,
        body: {
          'species_id': speciesId,
          'photo_id': ?photoId,
          if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
          'room': ?room,
          'indoor': ?indoor,
        },
      );

  Future<void> remove(String id, {bool keepPhotos = false}) => _http.delete(
        '/plants/$id',
        (_) {},
        query: {'keep_photos': keepPhotos},
      );

  Future<Plant> water(String id, {int? amountMl, DateTime? at}) => _http.post(
        '/plants/$id/water',
        _plant,
        body: {
          'amount_ml': ?amountMl,
          if (at != null) 'at': at.toUtc().toIso8601String(),
        },
      );

  /// `reason` is `soil_wet`, `away` or `forgot`. Only `soil_wet` moves the
  /// next watering; the other two just record that it was not done.
  Future<Plant> skipWatering(String id, String reason) => _http.post(
        '/plants/$id/water/skip',
        _plant,
        body: {'reason': reason},
      );

  /// A quick note without a photo. One to seven chips, no repeats; `text` is
  /// at most 200 characters and is never parsed.
  Future<Plant> addNote(String id, List<String> chips, {String? text}) =>
      _http.post(
        '/plants/$id/notes',
        _plant,
        body: {
          'chips': chips,
          if (text != null && text.trim().isNotEmpty) 'text': text.trim(),
        },
      );

  /// Only a paused plant can be resumed; a stale one is `409
  /// plant_not_paused` and comes back through a check-in.
  Future<Plant> resume(String id) => _http.post('/plants/$id/resume', _plant);

  /// Every course the plant has had, newest first, closed ones included.
  Future<List<Treatment>> treatments(String id) => _http.get(
        '/plants/$id/treatments',
        (json) => Json.list(json is Map ? json['items'] : json)
            .map(Treatment.fromJson)
            .toList(),
      );

  /// Every treatment plan the plant has had, newest first, closed ones
  /// included. One plan per plant at a time; its problems are worst first
  /// and its steps are the whole plan in one order.
  Future<List<Course>> courses(String id) => _http.get(
        '/plants/$id/courses',
        (json) => Json.list(json is Map ? json['items'] : json)
            .map(Course.fromJson)
            .toList(),
      );

  /// Stops every open problem on the plan at once. Same body as a single
  /// treatment's abandon.
  Future<Course> abandonCourse(String courseId, String reason,
          {String? note}) =>
      _http.post(
        '/courses/$courseId/abandon',
        (json) => Course.fromJson(Json.map(json)),
        body: {
          'reason': reason,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        },
      );

  /// `reason` is `too_hard`, `plant_recovered` or `other`.
  Future<Treatment> abandonTreatment(String treatmentId, String reason,
          {String? note}) =>
      _http.post(
        '/treatments/$treatmentId/abandon',
        (json) => Treatment.fromJson(Json.map(json)),
        body: {
          'reason': reason,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        },
      );

  Future<Plant> patch(String id, Map<String, Object?> changes) =>
      _http.patch('/plants/$id', _plant, body: changes);

  Future<Plant> updateSchedule(String id, Map<String, Object?> changes) =>
      _http.put('/plants/$id/schedule', _plant, body: changes);

  Future<Plant> correctSpecies(String id, String speciesId) => _http.post(
        '/plants/$id/species',
        _plant,
        body: {'species_id': speciesId},
      );

  /// `range` is `7d`, `30d` or `90d`.
  Future<List<HealthPoint>> history(String id, String range) => _http.get(
        '/plants/$id/history',
        (json) => HealthPoint.listFromJson(json is Map ? json['items'] : json),
        query: {'range': range},
      );

  Future<List<CareEvent>> careEvents(String id) => _http.get(
        '/plants/$id/care-events',
        (json) => Json.list(json is Map ? json['items'] : json)
            .map(CareEvent.fromJson)
            .toList(),
      );

  Future<Map<String, dynamic>> carePlan(String id) =>
      _http.get('/plants/$id/care-plan', Json.map);

  Future<List<CareTask>> todaysCare() => _http.get(
        '/care/today',
        (json) => Json.list(json is Map ? json['items'] : json)
            .map(CareTask.fromJson)
            .toList(),
      );

  Future<CareTask> completeTask(String clientId) => _http.post(
        '/care/tasks/$clientId/complete',
        (json) => CareTask.fromJson(Json.map(json)),
      );

  /// Treatment steps only (`400 task_not_skippable` otherwise). The step
  /// becomes `skipped` and does not come back on its cadence.
  Future<CareTask> skipTask(String clientId, {String? reason}) => _http.post(
        '/care/tasks/$clientId/skip',
        (json) => CareTask.fromJson(Json.map(json)),
        body: {
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
        },
      );

  /// Step 2 of a check-in: hands the photo to the analyser (§3.4).
  Future<String> submitConditionUpdate(
    String plantId, {
    required String photoId,
    required String userVerdict,
    required List<String> observations,
    required String note,
  }) =>
      _http.post(
        '/plants/$plantId/condition-updates',
        (json) => Json.str(Json.map(json)['job_id']),
        body: {
          'photo_id': photoId,
          'user_verdict': userVerdict,
          'observations': observations,
          'note': note,
        },
      );
}
