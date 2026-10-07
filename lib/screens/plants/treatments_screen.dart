import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../domain/models/treatment.dart';
import '../../enum.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_chip.dart';
import '../../shared/components/app_surfaces.dart';
import '../../shared/components/app_toast.dart';
import '../../shared/components/care_sheets.dart';
import '../../shared/components/headers.dart';
import '../../shared/components/pressable.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../shared/widgets/skeleton.dart';
import '../../stores/plant_detail_store.dart';
import '../../theme.dart';
import '../../utils/app_clock.dart';
import '../../utils/date_format.dart';

/// The plant's treatment plans, newest first, closed ones included.
///
/// A plant has one plan at a time: every problem a photo found, grouped,
/// with the steps merged into one order. Plans open on their own — from the
/// identification, or from a check-in that found a problem — and every
/// check-in judges every open problem, so the list is rendered as history
/// rather than as a to-do list. Today's steps live on the home screen.
class TreatmentsScreen extends StatefulWidget {
  const TreatmentsScreen({super.key, required this.store});

  final PlantDetailStore store;

  @override
  State<TreatmentsScreen> createState() => _TreatmentsScreenState();
}

class _TreatmentsScreenState extends State<TreatmentsScreen> {
  PlantDetailStore get _store => widget.store;

  @override
  void initState() {
    super.initState();
    _store.loadCourses();
  }

  Future<void> _stopProblem(CourseProblem problem) async {
    final stopped = await showAbandonSheet(
      context,
      title: 'Stop treating ${problem.problem.toLowerCase()}?',
      body: 'Its steps leave today\'s list; the rest of the plan carries on.',
      onAbandon: (reason, note) =>
          _store.abandonProblem(problem, reason, note: note),
    );
    _report(stopped, 'Treatment stopped');
  }

  Future<void> _stopPlan(Course course) async {
    final stopped = await showAbandonSheet(
      context,
      title: 'Stop the whole plan?',
      body: 'Every problem on it stops at once and all of its steps leave '
          'today\'s list. The plan stays in the history.',
      onAbandon: (reason, note) =>
          _store.abandonCourse(course, reason, note: note),
    );
    _report(stopped, 'Plan stopped');
  }

  void _report(bool ok, String message) {
    if (!mounted) return;
    if (ok) {
      AppToast.show(context, message: message);
    } else if (_store.errorMessage != null) {
      AppToast.show(context, message: _store.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plant = _store.plant;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.lightOverlay,
      child: Scaffold(
        backgroundColor: AppColors.ground,
        body: ScreenBackground(
          glow: false,
          child: SafeArea(
            bottom: false,
            child: Observer(
              builder: (context) {
                final courses = _store.courses;
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                          AppSpacing.lg, AppSpacing.gutter, 0),
                      sliver: SliverToBoxAdapter(
                        child: NavHeader(
                          title: 'Treatment plan',
                          subtitle: plant?.nickname,
                          onBack: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                    ),
                    if (!_store.coursesLoaded)
                      const SliverPadding(
                        padding: EdgeInsets.fromLTRB(AppSpacing.gutter,
                            AppSpacing.xl, AppSpacing.gutter, 0),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            children: [
                              Skeleton(height: 220, radius: AppRadius.card),
                              SizedBox(height: AppSpacing.lg),
                              Skeleton(height: 140, radius: AppRadius.card),
                            ],
                          ),
                        ),
                      )
                    else if (courses.isEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                            AppSpacing.xxxl, AppSpacing.gutter, 0),
                        sliver: SliverToBoxAdapter(
                          child: AppCard(
                            padding: const EdgeInsets.all(
                                AppSpacing.cardPaddingLarge),
                            child: Column(
                              children: [
                                const IconTile(
                                    icon: PgIcons.leaf,
                                    tone: MetricStatus.good,
                                    size: 56),
                                const SizedBox(height: AppSpacing.lg),
                                Text('Nothing to treat',
                                    style: AppText.heading20
                                        .copyWith(fontSize: 20.5)),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'A plan opens on its own when a check-in '
                                  'photo shows a problem.',
                                  textAlign: TextAlign.center,
                                  style: AppText.body15.copyWith(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                            AppSpacing.xl, AppSpacing.gutter, 0),
                        sliver: SliverList.separated(
                          itemCount: courses.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.lg),
                          itemBuilder: (context, i) => _CourseCard(
                            course: courses[i],
                            // Only the newest plan can still be open, so
                            // older ones start folded.
                            initiallyExpanded: i == 0,
                            busy: _store.isBusy,
                            onStopProblem: _stopProblem,
                            onStopPlan: () => _stopPlan(courses[i]),
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: AppSpacing.section +
                            MediaQuery.viewPaddingOf(context).bottom,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// One plan: its header, the problems on it (worst first), then every step
/// in the plan's own order. A step that serves every problem is shown once,
/// labelled "All problems", never under one problem.
class _CourseCard extends StatefulWidget {
  const _CourseCard({
    required this.course,
    required this.initiallyExpanded,
    required this.busy,
    required this.onStopProblem,
    required this.onStopPlan,
  });

  final Course course;
  final bool initiallyExpanded;
  final bool busy;
  final void Function(CourseProblem problem) onStopProblem;
  final VoidCallback onStopPlan;

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> {
  late bool _expanded = widget.initiallyExpanded;

  Course get _course => widget.course;

  MetricStatus get _tone {
    if (!_course.isOpen) return MetricStatus.neutral;
    return switch (_course.severity) {
      ProblemSeverity.high => MetricStatus.bad,
      ProblemSeverity.medium => MetricStatus.watch,
      _ => MetricStatus.good,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = _course;
    final open = c.openProblems;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Pressable(
            onTap: () => setState(() => _expanded = !_expanded),
            semanticLabel: _expanded ? 'Collapse plan' : 'Expand plan',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.isOpen
                            ? 'Current plan'
                            : 'Plan from ${AppDate.dayMonth(c.startedAt)}',
                        style: AppText.heading20.copyWith(fontSize: 20.5),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        c.isOpen
                            ? '${open.length} of ${c.problems.length} '
                                'problem${c.problems.length == 1 ? '' : 's'} '
                                'still being treated'
                            : '${c.problems.length} '
                                'problem${c.problems.length == 1 ? '' : 's'}'
                                '${c.closedAt == null ? '' : ' · closed ${AppDate.dayMonth(c.closedAt!)}'}',
                        style: AppText.body13.copyWith(fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                TagPill(
                  label: c.isOpen
                      ? (severityLabel(c.severity).isEmpty
                          ? 'In progress'
                          : severityLabel(c.severity))
                      : 'Closed',
                  tone: _tone,
                  dense: true,
                ),
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: PgIcon(
                    _expanded ? PgIcons.chevronDown : PgIcons.chevronRight,
                    size: 20,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          if (c.isOpen) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const PgIcon(PgIcons.calendar,
                    size: 16, color: AppColors.inkFaint),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Judged at the check-in around '
                    '${AppDate.weekdayDayMonth(c.reviewAt)}',
                    style: AppText.body13.copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
          if (_expanded) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(height: 1, color: AppColors.line),
            const SizedBox(height: AppSpacing.lg),
            const CaptionLabel('Problems', color: AppColors.inkFaint),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < c.problems.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              _ProblemRow(
                problem: c.problems[i],
                busy: widget.busy,
                onStop: c.problems[i].isOpen
                    ? () => widget.onStopProblem(c.problems[i])
                    : null,
              ),
            ],
            if (c.steps.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              const Divider(height: 1, color: AppColors.line),
              const SizedBox(height: AppSpacing.lg),
              const CaptionLabel('Steps', color: AppColors.inkFaint),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < c.steps.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                _StepRow(
                  step: c.steps[i],
                  label: c.problemLabel(c.steps[i].problemId),
                ),
              ],
            ],
            if (c.isOpen && open.length > 1) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton.outline(
                label: 'Stop the whole plan',
                height: 50,
                fontSize: 15,
                loading: widget.busy,
                onPressed: widget.onStopPlan,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// One problem on the plan, with its own status and, while open, its own
/// stop action. Stopping the last open problem closes the plan.
class _ProblemRow extends StatelessWidget {
  const _ProblemRow({
    required this.problem,
    required this.busy,
    required this.onStop,
  });

  final CourseProblem problem;
  final bool busy;
  final VoidCallback? onStop;

  MetricStatus get _tone => switch (problem.status) {
        TreatmentStatus.resolved || TreatmentStatus.improving =>
          MetricStatus.good,
        TreatmentStatus.active => MetricStatus.watch,
        TreatmentStatus.escalated => MetricStatus.bad,
        TreatmentStatus.superseded ||
        TreatmentStatus.abandoned =>
          MetricStatus.neutral,
      };

  @override
  Widget build(BuildContext context) {
    final p = problem;
    final sev = severityLabel(p.severity);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconTile(
          icon: PgIcons.alertCircle,
          tone: p.isOpen
              ? (p.severity == ProblemSeverity.high
                  ? MetricStatus.bad
                  : MetricStatus.watch)
              : MetricStatus.neutral,
          size: 40,
          radius: 13,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.problem,
                  style: AppText.heading17.copyWith(fontSize: 15.5)),
              const SizedBox(height: 2),
              Text(
                [
                  if (sev.isNotEmpty) sev,
                  'added ${AppDate.dayMonth(p.addedAt)}',
                  if (p.tier > 1) 'second course',
                ].join(' · '),
                style: AppText.body13.copyWith(fontSize: 13.5),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  TagPill(label: p.statusLabel, tone: _tone, dense: true),
                  if (onStop != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      label: 'Stop',
                      style: AppButtonStyle.link,
                      expand: false,
                      height: 30,
                      fontSize: 13.5,
                      onPressed: busy ? null : onStop,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One step, labelled with the problem it serves.
class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.label});

  final TreatmentStep step;
  final String label;

  int get _daysUntilDue {
    final n = AppClock.now();
    return step.dueAt.difference(DateTime(n.year, n.month, n.day)).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final (icon, tone, stamp) = switch (step.status) {
      TreatmentStepStatus.done => (
          PgIcons.check,
          MetricStatus.good,
          step.doneAt == null ? 'Done' : 'Done ${AppDate.dayMonth(step.doneAt!)}'
        ),
      TreatmentStepStatus.skipped => (
          PgIcons.minus,
          MetricStatus.watch,
          step.skipReason?.isNotEmpty == true
              ? 'Skipped · ${step.skipReason}'
              : 'Skipped'
        ),
      // The system dropped it for a stronger course; not the keeper's doing.
      TreatmentStepStatus.superseded => (
          PgIcons.refresh,
          MetricStatus.neutral,
          'No longer needed'
        ),
      TreatmentStepStatus.pending => (
          PgIcons.calendar,
          MetricStatus.neutral,
          'Due ${AppDate.relativeDue(_daysUntilDue).toLowerCase()}'
              '${step.cadenceDays != null ? ' · every ${step.cadenceDays} days' : ''}'
        ),
    };
    final muted = step.status == TreatmentStepStatus.superseded;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconTile(icon: icon, tone: tone, size: 40, radius: 13),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    label.toUpperCase(),
                    style: AppText.caption12.copyWith(
                      fontSize: 11,
                      letterSpacing: 1.1,
                      color: step.servesWholePlan
                          ? AppColors.healthyDeep
                          : AppColors.inkFaint,
                    ),
                  ),
                ),
              Text(
                step.title,
                style: AppText.heading17.copyWith(
                  fontSize: 15.5,
                  color: muted ? AppColors.inkMuted : AppColors.ink,
                  decoration: muted ? TextDecoration.lineThrough : null,
                  decorationColor: AppColors.inkMuted,
                ),
              ),
              if (step.detail.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(step.detail,
                    style: AppText.body13.copyWith(fontSize: 13.5)),
              ],
              const SizedBox(height: 2),
              Text(stamp,
                  style: AppText.caption12.copyWith(
                    color: step.status == TreatmentStepStatus.pending &&
                            _daysUntilDue < 0
                        ? AppColors.cautionDeep
                        : AppColors.inkFaint,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}
