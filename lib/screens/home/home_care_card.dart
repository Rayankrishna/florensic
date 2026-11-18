import 'package:flutter/material.dart';

import '../../domain/models/care_task.dart';
import '../../enum.dart';
import '../../shared/components/app_chip.dart';
import '../../shared/components/app_surfaces.dart';
import '../../shared/components/pressable.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../theme.dart';

/// Today's care, folded by kind: one line for watering, one for check-ins,
/// one for treatment steps, one for environment. A day with forty tasks
/// across a dozen plants is four rows here; each opens the full list
/// filtered to that kind, where the tasks are ticked off.
class CareKindSummary {
  CareKindSummary(this.kind);

  final CareTaskKind kind;
  final List<CareTask> tasks = [];

  /// Nicknames of the plants with a task of this kind, in task order.
  final List<String> plants = [];

  int get total => tasks.length;
  int get done => tasks.where((t) => t.done).length;
  int get left => total - done;
  bool get complete => total > 0 && left == 0;
  bool get overdue => tasks.any((t) => t.overdue && !t.done);
}

/// The kinds in the order the card lists them.
const List<CareTaskKind> _kindOrder = [
  CareTaskKind.watering,
  CareTaskKind.condition,
  CareTaskKind.treatmentStep,
  CareTaskKind.environment,
  CareTaskKind.unknown,
];

/// Groups today's tasks by kind, keeping only the kinds present.
/// [plantName] resolves a plant id to its nickname.
List<CareKindSummary> summariseToday(
  List<CareTask> tasks,
  String? Function(String plantId) plantName,
) {
  final byKind = <CareTaskKind, CareKindSummary>{};
  for (final task in tasks) {
    final summary = byKind.putIfAbsent(task.kind, () => CareKindSummary(task.kind));
    summary.tasks.add(task);
    final name = plantName(task.plantId);
    if (name != null && !summary.plants.contains(name)) {
      summary.plants.add(name);
    }
  }
  return [
    for (final kind in _kindOrder)
      if (byKind[kind] != null) byKind[kind]!,
  ];
}

String careKindLabel(CareTaskKind kind) => switch (kind) {
      CareTaskKind.watering => 'Watering',
      CareTaskKind.condition => 'Check-ins',
      CareTaskKind.treatmentStep => 'Treatment steps',
      CareTaskKind.environment => 'Environment',
      CareTaskKind.unknown => 'Other',
    };

/// Icon and tint for a kind, shared with the task rows.
(PgIcons, Color, Color) careKindArt(CareTaskKind kind) => switch (kind) {
      CareTaskKind.watering => (
          PgIcons.droplet,
          AppColors.waterTint,
          AppColors.waterDeep
        ),
      CareTaskKind.condition => (
          PgIcons.camera,
          AppColors.cautionTint,
          AppColors.cautionDeep
        ),
      CareTaskKind.treatmentStep => (
          PgIcons.leaf,
          AppColors.leafSoft,
          AppColors.healthyDeep
        ),
      CareTaskKind.environment => (
          PgIcons.thermometer,
          AppColors.neutralTint,
          AppColors.inkMuted
        ),
      CareTaskKind.unknown => (
          PgIcons.calendar,
          AppColors.neutralTint,
          AppColors.inkMuted
        ),
    };

/// The card on Home: a progress bar over the day, then one row per kind.
class TodayCareCard extends StatelessWidget {
  const TodayCareCard({
    super.key,
    required this.summaries,
    required this.onOpenKind,
  });

  final List<CareKindSummary> summaries;
  final ValueChanged<CareTaskKind> onOpenKind;

  @override
  Widget build(BuildContext context) {
    final total = summaries.fold<int>(0, (n, s) => n + s.total);
    final done = summaries.fold<int>(0, (n, s) => n + s.done);
    final allDone = total > 0 && done == total;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadius.pillR,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: total == 0 ? 0 : done / total,
                    ),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: AppColors.track,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.leaf),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                allDone ? 'All $total done' : '$done of $total done',
                style: AppText.label13.copyWith(
                  fontSize: 13,
                  color: allDone ? AppColors.healthyDeep : AppColors.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < summaries.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.line),
            _KindRow(
              summary: summaries[i],
              onTap: () => onOpenKind(summaries[i].kind),
            ),
          ],
        ],
      ),
    );
  }
}

class _KindRow extends StatelessWidget {
  const _KindRow({required this.summary, required this.onTap});

  final CareKindSummary summary;
  final VoidCallback onTap;

  /// What the row says under its title: the plants for watering and
  /// check-ins, the step count for a treatment, the task for environment.
  String get _detail {
    final s = summary;
    final plants = s.plants;
    String who() => switch (plants.length) {
          0 => '',
          1 => plants.first,
          2 => '${plants[0]}, ${plants[1]}',
          _ => '${plants.length} plants',
        };
    switch (s.kind) {
      case CareTaskKind.treatmentStep:
        final steps = '${s.total} step${s.total == 1 ? '' : 's'}';
        if (s.complete) return 'All $steps done';
        final w = who();
        return w.isEmpty ? steps : '$steps · $w';
      case CareTaskKind.environment:
        if (s.complete) return 'Done';
        return s.total == 1
            ? s.tasks.first.title
            : '${s.total} task${s.total == 1 ? '' : 's'}';
      case CareTaskKind.watering:
      case CareTaskKind.condition:
      case CareTaskKind.unknown:
        if (s.complete) return 'Done';
        final w = who();
        return w.isEmpty ? '${s.total} tasks' : w;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final (icon, tint, deep) = careKindArt(s.kind);
    final complete = s.complete;
    return Pressable(
      onTap: onTap,
      semanticLabel: '${careKindLabel(s.kind)}, ${s.left} to do',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
        child: Row(
          children: [
            IconTile(
              icon: icon,
              tone: MetricStatus.neutral,
              size: 38,
              radius: 12,
              background: complete ? AppColors.softGreen : tint,
              foreground: complete ? AppColors.healthyDeep : deep,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    careKindLabel(s.kind),
                    style: AppText.heading17.copyWith(
                      fontSize: 15.5,
                      color: complete ? AppColors.inkMuted : AppColors.ink,
                      decoration: complete ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body13.copyWith(
                      fontSize: 13,
                      color: s.overdue
                          ? AppColors.cautionDeep
                          : AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (complete)
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.softGreen,
                  shape: BoxShape.circle,
                ),
                child: const PgIcon(
                  PgIcons.check,
                  size: 16,
                  color: AppColors.healthyDeep,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: s.overdue ? AppColors.cautionTint : AppColors.leafSoft,
                  borderRadius: AppRadius.pillR,
                ),
                child: Text(
                  '${s.left}',
                  style: AppText.label13.copyWith(
                    fontSize: 13,
                    color: s.overdue
                        ? AppColors.cautionDeep
                        : AppColors.healthyDeep,
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.xs),
            const PgIcon(
              PgIcons.chevronRight,
              size: 18,
              color: AppColors.inkMuted,
            ),
          ],
        ),
      ),
    );
  }
}
