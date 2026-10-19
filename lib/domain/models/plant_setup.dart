import '../core/json.dart';

/// One step a job has reached (`StageOut`).
///
/// [message] is written for the owner and meant to be shown verbatim;
/// [stage] is the stable code to branch on; [data] carries the numbers
/// behind the message when there are any — a score, a count.
class JobStage {
  const JobStage({
    required this.stage,
    required this.message,
    required this.at,
    this.data,
  });

  factory JobStage.fromJson(Map<String, dynamic> json) => JobStage(
        stage: Json.str(json['stage']),
        message: Json.str(json['message']),
        at: Json.date(json['at']),
        data: json['data'] is Map ? Json.map(json['data']) : null,
      );

  final String stage;
  final String message;
  final DateTime at;
  final Map<String, dynamic>? data;
}

/// The slow half of an add.
///
/// `POST /v1/plants` answers in about a second with the plant's database
/// half and this block; the treatment course and the first care plan are
/// drafted behind it by a setup job, narrated a stage at a time on
/// `GET /v1/plants/{id}/setup`. `done` is the signal that what the job wrote
/// — the courses, the care plan, today's treatment steps — is there to read.
class PlantSetup {
  const PlantSetup({
    required this.jobId,
    required this.state,
    required this.stages,
  });

  factory PlantSetup.fromJson(Map<String, dynamic> json) => PlantSetup(
        jobId: Json.str(json['job_id']),
        state: Json.str(json['state'], 'queued'),
        stages: Json.list(json['stages']).map(JobStage.fromJson).toList(),
      );

  static PlantSetup? fromJsonOrNull(Object? value) =>
      value is Map ? PlantSetup.fromJson(Json.map(value)) : null;

  final String jobId;

  /// `queued | running | done | failed`. A `plan_failed` stage still ends
  /// `done`: the plant is usable and the plan is written at the next
  /// revision trigger. `failed` is rare and also leaves the plant usable.
  final String state;

  /// The narration so far, oldest first.
  final List<JobStage> stages;

  bool get isDone => state == 'done';
  bool get isFailed => state == 'failed';
  bool get isTerminal => isDone || isFailed;

  /// The newest line — the one to show.
  JobStage? get latest => stages.isEmpty ? null : stages.last;
}
