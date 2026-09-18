import '../../enum.dart';

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
  });

  final String id;
  final String plantId;
  final String title;
  final String detail;
  final MetricKind kind;
  final bool overdue;
  bool done;
  String? doneAt;

  CareTask copyWith({bool? done, String? doneAt}) => CareTask(
        id: id,
        plantId: plantId,
        title: title,
        detail: detail,
        kind: kind,
        overdue: overdue,
        done: done ?? this.done,
        doneAt: doneAt ?? this.doneAt,
      );
}
