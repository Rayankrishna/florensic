import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../domain/models/care_task.dart';
import '../../enum.dart';
import '../../locator.dart';
import '../../routes.dart';
import '../../shared/components/app_bottom_sheet.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/care_sheets.dart';
import '../../shared/components/list_rows.dart';
import '../../shared/components/pressable.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../stores/plant_collection_store.dart';
import '../../theme.dart';

/// Today's care, row by row — shared by the home preview and the full page.

/// One of today's rows, resolved against the collection: a task opens its
/// own screen, a plant's folded treatment plan opens its sheet.
class TodayCareRow extends StatelessWidget {
  const TodayCareRow({super.key, required this.item});

  final TodayItem item;

  @override
  Widget build(BuildContext context) {
    final collection = locator<PlantCollectionStore>();
    final steps = item.steps;
    if (steps != null) {
      final nickname =
          collection.plantById(item.plantId)?.nickname ?? 'Your plant';
      return TreatmentPlanRow(
        nickname: nickname,
        steps: steps,
        onOpen: () => showTreatmentPlanSheet(
          context,
          plantId: item.plantId,
          nickname: nickname,
        ),
      );
    }
    final task = item.task!;
    return CareTaskRow(
      task: task,
      onToggle: () => collection.completeTask(task.id),
      onSkip: task.skippable ? () => showSkipStepSheet(context, task) : null,
      onOpen: () {
        final plant = collection.plantById(task.plantId);
        if (plant == null) return;
        Navigator.of(context).pushNamed(
          task.kind == CareTaskKind.condition
              ? AppRoutes.conditionUpdate
              : AppRoutes.plantDetail,
          arguments: plant,
        );
      },
    );
  }
}

/// One row of today's list: a task on its own, or a plant's treatment steps
/// folded together — those open as a sheet rather than stacking up here.
class TodayItem {
  const TodayItem.task(this.task)
      : plantId = '',
        steps = null;

  TodayItem.plan(this.plantId, CareTask first)
      : task = null,
        steps = [first];

  final CareTask? task;
  final String plantId;
  final List<CareTask>? steps;
}

List<TodayItem> todayItems(List<CareTask> tasks) {
  final items = <TodayItem>[];
  final plans = <String, TodayItem>{};
  for (final task in tasks) {
    if (task.kind != CareTaskKind.treatmentStep) {
      items.add(TodayItem.task(task));
      continue;
    }
    final plan = plans[task.plantId];
    if (plan != null) {
      plan.steps!.add(task);
    } else {
      final item = TodayItem.plan(task.plantId, task);
      plans[task.plantId] = item;
      items.add(item);
    }
  }
  return items;
}

/// A plant's treatment steps for today, as one row: how many are left and
/// what they treat. The steps themselves live in the sheet it opens.
class TreatmentPlanRow extends StatelessWidget {
  const TreatmentPlanRow({
    super.key,
    required this.nickname,
    required this.steps,
    required this.onOpen,
  });

  final String nickname;
  final List<CareTask> steps;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final left = steps.where((s) => !s.done).length;
    final allDone = left == 0;
    final overdue = steps.any((s) => s.overdue && !s.done);
    // "All problems" is the plan's own step, not a problem to name.
    final problems = {
      for (final s in steps)
        if (!s.servesWholePlan && s.problem != null && s.problem!.isNotEmpty)
          s.problem!,
    };
    final count = allDone
        ? 'All ${steps.length} steps done'
        : '$left of ${steps.length} steps to do';
    return TileRow(
      icon: PgIcons.leaf,
      title: 'Treatment plan · $nickname',
      detail: problems.isEmpty ? count : '$count · ${problems.join(', ')}',
      detailMaxLines: 1,
      padding: const EdgeInsets.all(AppSpacing.md),
      iconSize: 44,
      strikeThrough: allDone,
      background: allDone ? const Color(0xFFF7FAF9) : AppColors.surface,
      elevated: !allDone,
      detailColor: overdue ? AppColors.cautionDeep : null,
      iconBackground: allDone ? AppColors.softGreen : AppColors.leafSoft,
      iconForeground: AppColors.healthyDeep,
      onTap: onOpen,
      trailing: CircleIconButton(
        icon: PgIcons.chevronRight,
        size: 40,
        background: AppColors.leaf,
        foreground: Colors.white,
        elevated: false,
        onPressed: onOpen,
      ),
    );
  }
}

/// The steps behind a [TreatmentPlanRow], one compact row each with the
/// same tap-to-act behaviour as the list. It reads the collection live, so
/// a step ticked here updates the row behind the sheet as well.
Future<void> showTreatmentPlanSheet(
  BuildContext context, {
  required String plantId,
  required String nickname,
}) {
  final collection = locator<PlantCollectionStore>();
  return AppBottomSheet.show<void>(
    context,
    builder: (sheetContext) => Observer(
      builder: (context) {
        final steps = collection.tasks
            .where((t) =>
                t.kind == CareTaskKind.treatmentStep && t.plantId == plantId)
            .toList();
        final done = steps.where((s) => s.done).length;
        return AppBottomSheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text('Treatment plan',
                        style: AppText.title28.copyWith(fontSize: 23)),
                  ),
                  Text('$done of ${steps.length} done',
                      style: AppText.body13.copyWith(fontSize: 14)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(nickname, style: AppText.body15.copyWith(fontSize: 15)),
              const SizedBox(height: AppSpacing.xl),
              if (steps.isEmpty)
                Text('Nothing left to do today.',
                    style: AppText.body15.copyWith(fontSize: 15)),
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                CareTaskRow(
                  task: steps[i],
                  onToggle: () => collection.completeTask(steps[i].id),
                  onSkip: steps[i].skippable
                      ? () => showSkipStepSheet(sheetContext, steps[i])
                      : null,
                  onOpen: () {
                    final plant = collection.plantById(plantId);
                    Navigator.of(sheetContext).pop();
                    if (plant == null) return;
                    Navigator.of(context).pushNamed(
                      AppRoutes.plantDetail,
                      arguments: plant,
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}

/// One of today's tasks. Four kinds share the row; a kind this build does
/// not know still shows its own title and detail and can be completed.
class CareTaskRow extends StatelessWidget {
  const CareTaskRow({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onOpen,
    this.onSkip,
  });

  final CareTask task;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  /// Only a treatment step can be skipped.
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final done = task.done;
    final kind = task.kind;
    final overdue = task.overdue;
    // A step's full instruction is a paragraph: the row shows only the
    // problem it serves, and the sheet that opens on tap has the rest.
    final step = kind == CareTaskKind.treatmentStep;
    final problem = task.problem;
    final detail = step && problem != null && problem.isNotEmpty
        ? problem
        : task.detail;
    final (icon, tint, deep) = switch (kind) {
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

    return TileRow(
      icon: icon,
      title: task.title,
      detail: detail,
      titleMaxLines: 2,
      detailMaxLines: step ? 1 : 2,
      padding: const EdgeInsets.all(AppSpacing.md),
      iconSize: 44,
      strikeThrough: done,
      background: done ? const Color(0xFFF7FAF9) : AppColors.surface,
      elevated: !done,
      detailColor: overdue ? AppColors.cautionDeep : null,
      iconBackground: done ? AppColors.softGreen : tint,
      iconForeground: done ? AppColors.healthyDeep : deep,
      leading: done
          ? Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.softGreen,
                borderRadius: BorderRadius.circular(AppRadius.tile),
              ),
              child: const PgIcon(
                PgIcons.check,
                size: 22,
                color: AppColors.healthyDeep,
              ),
            )
          : null,
      onTap: done
          ? null
          : onSkip != null
              ? () => showTaskActions(context, task,
                  onComplete: onToggle, onSkip: onSkip!)
              : onOpen,
      trailing: done
          ? null
          : kind == CareTaskKind.condition
          ? CircleIconButton(
              icon: PgIcons.chevronRight,
              size: 40,
              background: AppColors.leaf,
              foreground: Colors.white,
              elevated: false,
              onPressed: onOpen,
            )
          : Pressable(
              onTap: onToggle,
              scale: 0.9,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.line, width: 1.6),
                ),
                child: const PgIcon(
                  PgIcons.check,
                  size: 20,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
    );
  }
}
