import '../core/json.dart';

/// Where a course stands. Closed states keep the course in the history.
enum TreatmentStatus {
  active,
  improving,
  escalated,
  resolved,
  superseded,
  abandoned,
}

enum TreatmentStepStatus { pending, done, skipped, superseded }

/// How grave a finding said the problem was.
enum ProblemSeverity { low, medium, high }

/// Why the owner stopped a course. The choice is not cosmetic: recovered
/// closes it as a resolution, too hard records care not given.
enum AbandonReason {
  tooHard('too_hard'),
  plantRecovered('plant_recovered'),
  other('other');

  const AbandonReason(this.wire);

  final String wire;
}

ProblemSeverity? _severityOf(Object? value) => value == null
    ? null
    : Json.enumOf(value, ProblemSeverity.values, ProblemSeverity.low);

String severityLabel(ProblemSeverity? severity) => switch (severity) {
      ProblemSeverity.high => 'Serious',
      ProblemSeverity.medium => 'Moderate',
      ProblemSeverity.low => 'Mild',
      null => '',
    };

/// One problem a plant has plus the course prescribed for it, opened by the
/// identification or by a check-in that found the problem. Every treatment
/// is one member of a [Course]; `/treatments` is the per-problem history.
class Treatment {
  const Treatment({
    required this.id,
    required this.plantId,
    required this.courseId,
    required this.problemId,
    required this.problem,
    required this.tier,
    required this.status,
    required this.startedAt,
    required this.reviewAt,
    required this.steps,
    this.severity,
    this.expectedDaysToImprove,
    this.recurrence = false,
    this.closedAt,
    this.abandonReason,
    this.supersededById,
  });

  factory Treatment.fromJson(Map<String, dynamic> json) => Treatment(
        id: Json.str(json['id']),
        plantId: Json.str(json['plant_id']),
        courseId: Json.str(json['course_id']),
        problemId: Json.str(json['problem_id']),
        problem: Json.str(json['problem'], 'Treatment'),
        severity: _severityOf(json['severity']),
        tier: Json.integer(json['tier'], 1),
        status: Json.enumOf(
          json['status'],
          TreatmentStatus.values,
          TreatmentStatus.active,
        ),
        startedAt: Json.date(json['started_at']),
        reviewAt: Json.day(json['review_at']),
        expectedDaysToImprove: Json.intOrNull(json['expected_days_to_improve']),
        recurrence: Json.boolean(json['recurrence']),
        closedAt: Json.dateOrNull(json['closed_at']),
        abandonReason: _abandonReasonOf(json['abandon_reason']),
        supersededById: _strOrNull(json['superseded_by_id']),
        steps: Json.list(json['steps']).map(TreatmentStep.fromJson).toList(),
      );

  final String id;
  final String plantId;

  /// The plan this treatment is one problem of.
  final String courseId;

  /// Stable taxonomy id, e.g. `pest.mealybug`.
  final String problemId;

  /// The display name, ready to show.
  final String problem;
  final ProblemSeverity? severity;

  /// 1 the first time; 2 for a problem back within ninety days.
  final int tier;
  final TreatmentStatus status;
  final DateTime startedAt;

  /// The owner-local date the course is meant to be judged.
  final DateTime reviewAt;
  final int? expectedDaysToImprove;
  final bool recurrence;
  final DateTime? closedAt;
  final AbandonReason? abandonReason;

  /// The course that replaced this one, when it was superseded.
  final String? supersededById;
  final List<TreatmentStep> steps;

  bool get isOpen => isOpenStatus(status);

  String get statusLabel => treatmentStatusLabel(status, abandonReason);
}

bool isOpenStatus(TreatmentStatus status) => switch (status) {
      TreatmentStatus.active ||
      TreatmentStatus.improving ||
      TreatmentStatus.escalated =>
        true,
      _ => false,
    };

String treatmentStatusLabel(TreatmentStatus status, AbandonReason? reason) =>
    switch (status) {
      TreatmentStatus.active => 'In progress',
      TreatmentStatus.improving => 'Improving',
      TreatmentStatus.escalated => 'Stepped up',
      TreatmentStatus.resolved => 'Resolved',
      TreatmentStatus.superseded => 'Replaced',
      TreatmentStatus.abandoned => switch (reason) {
          AbandonReason.plantRecovered => 'Stopped · plant recovered',
          AbandonReason.tooHard => 'Stopped · too hard',
          _ => 'Stopped',
        },
    };

AbandonReason? _abandonReasonOf(Object? value) => value == null
    ? null
    : Json.enumOf(value, AbandonReason.values, AbandonReason.other);

String? _strOrNull(Object? v) => v is String && v.isNotEmpty ? v : null;

/// One step of a course. A step with a cadence repeats until the review.
///
/// On a plan (`/courses`) each step also carries [problemId]: the problem it
/// serves, or `all` for a step that serves every problem on the plan — the
/// same vocabulary today's list uses, so one widget renders both.
class TreatmentStep {
  const TreatmentStep({
    required this.id,
    required this.treatmentId,
    required this.key,
    required this.position,
    required this.title,
    required this.detail,
    required this.dueAt,
    required this.status,
    this.cadenceDays,
    this.doneAt,
    this.skipReason,
    this.serves,
    this.problemId,
  });

  factory TreatmentStep.fromJson(Map<String, dynamic> json) {
    final serves = _strOrNull(json['serves']);
    return TreatmentStep(
      id: Json.str(json['id']),
      treatmentId: Json.str(json['treatment_id']),
      key: Json.str(json['key']),
      position: Json.integer(json['position']),
      title: Json.str(json['title']),
      detail: Json.str(json['detail']),
      dueAt: Json.day(json['due_at']),
      status: Json.enumOf(
        json['status'],
        TreatmentStepStatus.values,
        TreatmentStepStatus.pending,
      ),
      cadenceDays: Json.intOrNull(json['cadence_days']),
      doneAt: Json.dateOrNull(json['done_at']),
      skipReason: _strOrNull(json['skip_reason']),
      serves: serves,
      // A treatment's own steps have no `problem_id`; `serves: all` still
      // marks the shared ones.
      problemId: _strOrNull(json['problem_id']) ?? (serves == 'all' ? 'all' : null),
    );
  }

  final String id;

  /// The problem's row this step hangs from.
  final String treatmentId;
  final String key;
  final int position;
  final String title;
  final String detail;

  /// An owner-local date.
  final DateTime dueAt;
  final TreatmentStepStatus status;
  final int? cadenceDays;
  final DateTime? doneAt;
  final String? skipReason;

  /// The raw column behind [problemId]: `all` or null.
  final String? serves;

  /// A taxonomy id, or `all` for a step that serves the whole plan. Null on
  /// a step read from `/treatments` that serves its own problem.
  final String? problemId;

  bool get servesWholePlan => problemId == 'all' || serves == 'all';

  /// The client id of this step on today's care list.
  String get taskId => 'task-tstep-$id';
}

/// A plant's treatment plan: every problem it has, grouped, with the steps
/// merged into one order. A plant has one open plan at a time; a problem a
/// later check-in finds joins it rather than starting another.
class Course {
  const Course({
    required this.id,
    required this.plantId,
    required this.isOpen,
    required this.startedAt,
    required this.reviewAt,
    required this.problems,
    required this.steps,
    this.severity,
    this.closedAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: Json.str(json['id']),
        plantId: Json.str(json['plant_id']),
        isOpen: Json.str(json['status'], 'open') == 'open',
        severity: _severityOf(json['severity']),
        startedAt: Json.date(json['started_at']),
        reviewAt: Json.day(json['review_at']),
        closedAt: Json.dateOrNull(json['closed_at']),
        problems:
            Json.list(json['problems']).map(CourseProblem.fromJson).toList(),
        steps: Json.list(json['steps']).map(TreatmentStep.fromJson).toList(),
      );

  final String id;
  final String plantId;

  /// Open while any problem on it is.
  final bool isOpen;

  /// The worst problem's.
  final ProblemSeverity? severity;
  final DateTime startedAt;

  /// The earliest open problem's review date (owner-local).
  final DateTime reviewAt;
  final DateTime? closedAt;

  /// Worst first.
  final List<CourseProblem> problems;

  /// The whole plan in one order: shared steps first, then the worst
  /// problem's, then each protocol's own order.
  final List<TreatmentStep> steps;

  List<CourseProblem> get openProblems =>
      problems.where((p) => p.isOpen).toList(growable: false);

  /// The display name for a step's problem id, or "All problems".
  String problemLabel(String? problemId) {
    if (problemId == null) return '';
    if (problemId == 'all') return 'All problems';
    for (final p in problems) {
      if (p.problemId == problemId) return p.problem;
    }
    return problemId;
  }
}

/// One problem on a plan: a [Treatment] seen as a member of its course.
class CourseProblem {
  const CourseProblem({
    required this.treatmentId,
    required this.problemId,
    required this.problem,
    required this.tier,
    required this.status,
    required this.addedAt,
    required this.reviewAt,
    this.severity,
    this.findingId,
    this.closedAt,
    this.abandonReason,
    this.supersededById,
  });

  factory CourseProblem.fromJson(Map<String, dynamic> json) => CourseProblem(
        treatmentId: Json.str(json['treatment_id']),
        problemId: Json.str(json['problem_id']),
        problem: Json.str(json['problem'], 'Problem'),
        severity: _severityOf(json['severity']),
        tier: Json.integer(json['tier'], 1),
        status: Json.enumOf(
          json['status'],
          TreatmentStatus.values,
          TreatmentStatus.active,
        ),
        addedAt: Json.date(json['added_at']),
        findingId: _strOrNull(json['finding_id']),
        reviewAt: Json.day(json['review_at']),
        closedAt: Json.dateOrNull(json['closed_at']),
        abandonReason: _abandonReasonOf(json['abandon_reason']),
        supersededById: _strOrNull(json['superseded_by_id']),
      );

  /// The `Treatment` row, which is what a per-problem abandon stops.
  final String treatmentId;
  final String problemId;
  final String problem;
  final ProblemSeverity? severity;
  final int tier;
  final TreatmentStatus status;

  /// When this problem joined the plan: the same instant for everything one
  /// scan found, its own day for one a later check-in added.
  final DateTime addedAt;
  final String? findingId;
  final DateTime reviewAt;
  final DateTime? closedAt;
  final AbandonReason? abandonReason;
  final String? supersededById;

  bool get isOpen => isOpenStatus(status);

  String get statusLabel => treatmentStatusLabel(status, abandonReason);
}
