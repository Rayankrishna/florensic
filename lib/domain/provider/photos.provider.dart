import 'dart:async';

import 'package:dio/dio.dart';

import '../../interceptors/api_interceptor.dart';
import '../core/json.dart';
import '../core/services_config.dart';
import '../models/plant.dart';
import '../models/plant_condition_update.dart';
import '../models/plant_species.dart';

/// Where a photo came from and what it is for.
enum PhotoPurpose { identify, checkin }

/// A queued analysis job.
class AnalysisJob {
  const AnalysisJob({
    required this.jobId,
    required this.photoId,
    required this.state,
    this.species,
    this.confidence,
    this.rationale,
    this.alternatives = const [],
    this.findings = const [],
    this.initialHealth,
    this.checkin,
    this.error,
    this.retryable = false,
  });

  factory AnalysisJob.fromJson(Map<String, dynamic> json) {
    final speciesJson = Json.map(json['species']);
    return AnalysisJob(
      jobId: Json.str(json['job_id'], Json.str(json['id'])),
      photoId: Json.str(json['photo_id']),
      state: Json.str(json['state'], 'queued'),
      species:
          speciesJson.isEmpty ? null : PlantSpecies.fromJson(speciesJson),
      confidence: Json.intOrNull(json['confidence']),
      rationale: Json.str(json['rationale']),
      alternatives: Json.list(json['alternatives'])
          .map(AnalysisAlternative.fromJson)
          .toList(),
      findings:
          Json.list(json['findings']).map(AnalysisFinding.fromJson).toList(),
      initialHealth: json['initial_health'] == null
          ? null
          : Json.map(json['initial_health']),
      checkin: json['checkin'] == null ? null : Json.map(json['checkin']),
      error: Json.str(json['error']),
      retryable: Json.boolean(json['retryable']),
    );
  }

  final String jobId;
  final String photoId;

  /// `queued | running | done | no_confident_match | failed`.
  final String state;
  final PlantSpecies? species;
  final int? confidence;
  final String? rationale;
  final List<AnalysisAlternative> alternatives;

  /// The typed problems the scan saw. One with a real severity opens a
  /// treatment on the spot when the plant is kept.
  final List<AnalysisFinding> findings;
  final Map<String, dynamic>? initialHealth;
  final Map<String, dynamic>? checkin;
  final String? error;
  final bool retryable;

  bool get isTerminal => const {'done', 'no_confident_match', 'failed'}
      .contains(state);

  bool get isDone => state == 'done';

  bool get isNoMatch => state == 'no_confident_match';

  bool get isFailed => state == 'failed';

  /// The updated plant carried back by a finished check-in.
  Plant? get checkinPlant {
    final payload = checkin;
    if (payload == null || payload['plant'] == null) return null;
    return Plant.fromJson(Json.map(payload['plant']));
  }

  /// `checkin.update` plus the `score_delta` beside it, once the job is done.
  ConditionUpdate? get checkinUpdate {
    final payload = checkin;
    if (payload == null || payload['update'] is! Map) return null;
    return ConditionUpdate.fromJson(
      Json.map(payload['update']),
      scoreDelta: Json.intOrNull(payload['score_delta']),
    );
  }

  /// `checkin.next_check_in`, an owner-local date.
  DateTime? get nextCheckIn => Json.dayOrNull(checkin?['next_check_in']);
}

/// A problem the model saw in the photo.
class AnalysisFinding {
  const AnalysisFinding({
    required this.type,
    required this.name,
    required this.severity,
    required this.confidence,
    this.problemId,
  });

  factory AnalysisFinding.fromJson(Map<String, dynamic> json) =>
      AnalysisFinding(
        type: Json.str(json['type'], 'none'),
        name: Json.str(json['name']),
        problemId:
            json['problem_id'] is String ? json['problem_id'] as String : null,
        severity: Json.str(json['severity'], 'none'),
        confidence: Json.integer(json['confidence']),
      );

  /// `disease | pest | abiotic | nutrient | none`.
  final String type;
  final String name;

  /// Stable taxonomy id (`pest.spider_mite`); null on rows older than the
  /// taxonomy.
  final String? problemId;
  final String severity;
  final int confidence;

  bool get isProblem => type != 'none' && severity != 'none';
}

/// A runner-up identification.
class AnalysisAlternative {
  const AnalysisAlternative({
    required this.species,
    required this.scientificName,
    required this.confidence,
  });

  factory AnalysisAlternative.fromJson(Map<String, dynamic> json) {
    final speciesJson = Json.map(json['species']);
    return AnalysisAlternative(
      species: speciesJson.isEmpty ? null : PlantSpecies.fromJson(speciesJson),
      scientificName: Json.str(json['scientific_name']),
      confidence: Json.integer(json['confidence']),
    );
  }

  /// Null when the catalogue has no entry — show [scientificName] instead.
  final PlantSpecies? species;
  final String scientificName;
  final int confidence;
}

/// `/v1/photos` and `/v1/analysis/{job_id}`.
class PhotosProvider {
  const PhotosProvider();

  HttpClient get _http => http!;

  /// Uploads a capture and returns the queued job.
  ///
  /// A `checkin` photo creates its job but does not run it — that happens
  /// when the condition update is submitted (§3.4).
  Future<AnalysisJob> upload({
    required String filePath,
    required PhotoPurpose purpose,
    String? plantId,
    String framing = 'leaf',
    String source = 'camera',
    double? lat,
    double? lon,
    double? locationAccuracyM,
    DateTime? capturedAt,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: 'photo.jpg'),
      'purpose': purpose.name,
      'framing': framing,
      'source': source,
      'plant_id': ?plantId,
      'lat': ?lat,
      'lon': ?lon,
      'location_accuracy_m': ?locationAccuracyM,
      if (capturedAt != null)
        'captured_at': capturedAt.toUtc().toIso8601String(),
    });
    return _http.post(
      '/photos',
      (json) => AnalysisJob.fromJson(Json.map(json)),
      body: form,
    );
  }

  Future<AnalysisJob> job(String jobId) => _http.get(
        '/analysis/$jobId',
        (json) => AnalysisJob.fromJson(Json.map(json)),
      );

  /// Polls until the job reaches a terminal state.
  ///
  /// Identification takes 10–60 s and a check-in 10–40 s, so the ceiling is
  /// generous; [onTick] lets the UI keep its scanning state honest.
  Future<AnalysisJob> awaitJob(
    String jobId, {
    Duration interval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 3),
    void Function(AnalysisJob job)? onTick,
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (true) {
      final current = await job(jobId);
      onTick?.call(current);
      if (current.isTerminal) return current;
      if (DateTime.now().isAfter(deadline)) {
        throw const ApiException(
          'That is taking longer than expected. Please try again.',
          code: 'analysis_timeout',
        );
      }
      await Future<void>.delayed(interval);
    }
  }
}
