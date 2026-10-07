import '../../enum.dart';
import '../core/json.dart';

/// A row in `Today's care` on the home dashboard.
class CareTask {
  CareTask({
    required this.id,
    required this.plantId,
    required this.title,
    required this.detail,
    required this.kind,
    required this.overdue,
    this.done = false,
    this.doneAt,
    this.courseId,
    this.problemId,
    this.problem,
  });

  /// `id` is the task's `client_id` — that is what `/care/tasks/{id}/complete`
  /// expects.
  factory CareTask.fromJson(Map<String, dynamic> json) => CareTask(
        id: Json.str(json['client_id'], Json.str(json['id'])),
        plantId: Json.str(json['plant_id']),
        title: Json.str(json['title']),
        detail: Json.str(json['detail']),
        kind: Json.enumOf(
          json['kind'],
          CareTaskKind.values,
          CareTaskKind.unknown,
        ),
        overdue: Json.boolean(json['overdue']),
        done: Json.boolean(json['done']),
        doneAt: json['done_at'] is String ? json['done_at'] as String : null,
        courseId: _strOrNull(json['course_id']),
        problemId: _strOrNull(json['problem_id']),
        problem: _strOrNull(json['problem']),
      );

  static String? _strOrNull(Object? v) => v is String && v.isNotEmpty ? v : null;

  final String id;
  final String plantId;
  final String title;
  final String detail;
  final CareTaskKind kind;
  final bool overdue;
  bool done;
  String? doneAt;

  /// Treatment steps only: the plan the step belongs to and the problem it
  /// serves, as a taxonomy id plus its display name. `problemId` is `all`
  /// (with `problem` "All problems") for a step that serves the whole plan.
  /// All three are null on the other kinds.
  final String? courseId;
  final String? problemId;
  final String? problem;

  /// Only a treatment step can be skipped.
  bool get skippable => kind == CareTaskKind.treatmentStep;

  bool get servesWholePlan => problemId == 'all';

  CareTask copyWith({bool? done, String? doneAt}) => CareTask(
        id: id,
        plantId: plantId,
        title: title,
        detail: detail,
        kind: kind,
        overdue: overdue,
        done: done ?? this.done,
        doneAt: doneAt ?? this.doneAt,
        courseId: courseId,
        problemId: problemId,
        problem: problem,
      );
}
