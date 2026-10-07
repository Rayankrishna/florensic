import 'package:flutter/material.dart';

import '../../domain/models/care_task.dart';
import '../../domain/models/treatment.dart';
import '../../domain/repositories/plant_repository.dart';
import '../../enum.dart';
import '../../locator.dart';
import '../../stores/plant_collection_store.dart';
import '../../theme.dart';
import '../widgets/pg_icon.dart';
import 'app_bottom_sheet.dart';
import 'app_button.dart';
import 'app_chip.dart';
import 'app_text_field.dart';
import 'app_toast.dart';
import 'pressable.dart';

/// The sheets behind the care actions the backend added: skipping a
/// watering or a treatment step, a quick note without a photo, and stopping
/// a treatment. Each one posts through the stores and reports the outcome.

/// Done or skip, for a treatment step on today's list.
Future<void> showTaskActions(
  BuildContext context,
  CareTask task, {
  required VoidCallback onComplete,
  required VoidCallback onSkip,
}) {
  return AppBottomSheet.show<void>(
    context,
    builder: (sheetContext) => AppBottomSheet(
      actions: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton.primary(
            label: 'Mark as done',
            icon: PgIcons.check,
            onPressed: () {
              Navigator.of(sheetContext).pop();
              onComplete();
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton.outline(
            label: 'Skip this step',
            onPressed: () {
              Navigator.of(sheetContext).pop();
              onSkip();
            },
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task.title, style: AppText.title28.copyWith(fontSize: 23)),
          if (task.detail.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(task.detail, style: AppText.body15.copyWith(fontSize: 15)),
          ],
        ],
      ),
    ),
  );
}

/// Skips a treatment step with an optional reason. The step is recorded as
/// skipped — it does not come back on its cadence, and it still counts as
/// care that was due.
Future<void> showSkipStepSheet(BuildContext context, CareTask task) async {
  final skipped = await AppBottomSheet.show<bool>(
    context,
    builder: (sheetContext) => _ReasonSheet(
      title: 'Skip this step?',
      body: 'It will not come back later in this course, and it still counts '
          'as care that was due.',
      textHint: 'Why are you skipping it? (optional)',
      textRequired: false,
      confirmLabel: 'Skip step',
      onConfirm: (_, text) =>
          locator<PlantCollectionStore>().skipTask(task.id, reason: text),
    ),
  );
  if (skipped == true && context.mounted) {
    AppToast.show(context, message: 'Step skipped');
  }
}

/// The three reasons mean three different things, so the sheet says what
/// each one does before the keeper picks it.
Future<bool> showWaterSkipSheet(
  BuildContext context, {
  required Future<bool> Function(WateringSkipReason reason) onSkip,
}) async {
  final result = await AppBottomSheet.show<bool>(
    context,
    builder: (sheetContext) => _ReasonSheet<WateringSkipReason>(
      title: 'Skip this watering?',
      body: 'Nothing here changes the health score.',
      options: [
        for (final r in WateringSkipReason.values)
          _Option(r, r.label, r.detail,
              icon: r == WateringSkipReason.soilWet
                  ? PgIcons.droplet
                  : PgIcons.clock),
      ],
      confirmLabel: 'Skip watering',
      onConfirm: (reason, _) => onSkip(reason!),
    ),
  );
  return result == true;
}

/// What the keeper can tell us without a camera. One to seven chips, an
/// optional line of text; it pulls the next check-in forward and never moves
/// the score.
Future<bool> showQuickNoteSheet(
  BuildContext context, {
  required Future<bool> Function(List<NoteChip> chips, String? text) onSave,
}) async {
  final result = await AppBottomSheet.show<bool>(
    context,
    builder: (sheetContext) => _QuickNoteSheet(onSave: onSave),
  );
  return result == true;
}

/// Stops a treatment — one problem's course, or the whole plan. The reason
/// is not cosmetic: "the plant recovered" closes it as a resolution, "too
/// hard" records care asked for and not given.
Future<bool> showAbandonSheet(
  BuildContext context, {
  required String title,
  required String body,
  required Future<bool> Function(AbandonReason reason, String? note) onAbandon,
}) async {
  final result = await AppBottomSheet.show<bool>(
    context,
    builder: (sheetContext) => _ReasonSheet<AbandonReason>(
      title: title,
      body: body,
      options: const [
        _Option(AbandonReason.plantRecovered, 'The plant recovered',
            'Closes it as resolved',
            icon: PgIcons.check),
        _Option(AbandonReason.tooHard, 'It was too hard to keep up',
            'Pauses this problem for two weeks',
            icon: PgIcons.pause),
        _Option(AbandonReason.other, 'Another reason', 'Just stop it',
            icon: PgIcons.dots),
      ],
      textHint: 'Add a note (optional)',
      textRequired: false,
      confirmLabel: 'Stop treatment',
      destructive: true,
      onConfirm: (reason, note) => onAbandon(reason!, note),
    ),
  );
  return result == true;
}

class _Option<T> {
  const _Option(this.value, this.label, this.detail, {required this.icon});

  final T value;
  final String label;
  final String detail;
  final PgIcons icon;
}

/// A picker of mutually exclusive reasons, an optional text line and one
/// confirming action. Pops `true` once [onConfirm] succeeds.
class _ReasonSheet<T> extends StatefulWidget {
  const _ReasonSheet({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.onConfirm,
    this.options = const [],
    this.textHint,
    this.textRequired = false,
    this.destructive = false,
  });

  final String title;
  final String body;
  final List<_Option<T>> options;
  final String? textHint;
  final bool textRequired;
  final String confirmLabel;
  final bool destructive;
  final Future<bool> Function(T? reason, String? text) onConfirm;

  @override
  State<_ReasonSheet<T>> createState() => _ReasonSheetState<T>();
}

class _ReasonSheetState<T> extends State<_ReasonSheet<T>> {
  static const int _maxChars = 200;

  T? _selected;
  final _text = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _canConfirm =>
      !_busy &&
      (widget.options.isEmpty || _selected != null) &&
      (!widget.textRequired || _text.text.trim().isNotEmpty);

  Future<void> _confirm() async {
    setState(() => _busy = true);
    final text = _text.text.trim();
    final ok = await widget.onConfirm(
      _selected,
      text.isEmpty ? null : text.substring(0, text.length.clamp(0, _maxChars)),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      actions: AppButton(
        label: widget.confirmLabel,
        style: widget.destructive
            ? AppButtonStyle.danger
            : AppButtonStyle.primary,
        loading: _busy,
        onPressed: _canConfirm ? _confirm : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: AppText.title28.copyWith(fontSize: 23)),
          const SizedBox(height: AppSpacing.sm),
          Text(widget.body, style: AppText.body15.copyWith(fontSize: 15)),
          if (widget.options.isNotEmpty) const SizedBox(height: AppSpacing.xl),
          for (var i = 0; i < widget.options.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            _OptionRow(
              option: widget.options[i],
              selected: _selected == widget.options[i].value,
              onTap: () => setState(() => _selected = widget.options[i].value),
            ),
          ],
          if (widget.textHint != null) ...[
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              hint: widget.textHint,
              controller: _text,
              maxLines: 3,
              minLines: 1,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionRow<T> extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _Option<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: option.label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected ? AppColors.leafSoft : AppColors.surface,
          borderRadius: AppRadius.cardR,
          border: Border.all(
            color: selected ? AppColors.leaf : AppColors.line,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            IconTile(
              icon: option.icon,
              tone: selected ? MetricStatus.good : MetricStatus.neutral,
              size: 44,
              radius: 14,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.label,
                      style: AppText.heading17.copyWith(fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(option.detail,
                      style: AppText.body13.copyWith(fontSize: 13.5)),
                ],
              ),
            ),
            if (selected)
              const PgIcon(PgIcons.check, size: 22, color: AppColors.healthyDeep),
          ],
        ),
      ),
    );
  }
}

class _QuickNoteSheet extends StatefulWidget {
  const _QuickNoteSheet({required this.onSave});

  final Future<bool> Function(List<NoteChip> chips, String? text) onSave;

  @override
  State<_QuickNoteSheet> createState() => _QuickNoteSheetState();
}

class _QuickNoteSheetState extends State<_QuickNoteSheet> {
  static const int _maxChars = 200;

  final _chips = <NoteChip>{};
  final _text = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final text = _text.text.trim();
    final ok = await widget.onSave(
      // Wire order is the enum's; the server only cares there are no repeats.
      NoteChip.values.where(_chips.contains).toList(),
      text.isEmpty ? null : text.substring(0, text.length.clamp(0, _maxChars)),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _maxChars - _text.text.length;
    return AppBottomSheet(
      actions: AppButton.primary(
        label: 'Save note',
        loading: _busy,
        onPressed: _chips.isEmpty || _busy ? null : _save,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('What have you noticed?',
              style: AppText.title28.copyWith(fontSize: 23)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No photo needed. A note brings the next check-in forward; it '
            'does not change the health score.',
            style: AppText.body15.copyWith(fontSize: 15),
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final chip in NoteChip.values)
                FilterChipPill(
                  label: chip.label,
                  selected: _chips.contains(chip),
                  onTap: () => setState(() {
                    if (!_chips.remove(chip)) _chips.add(chip);
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            hint: 'Anything else? (optional)',
            controller: _text,
            maxLines: 3,
            minLines: 1,
            onChanged: (_) => setState(() {}),
          ),
          if (remaining < 40) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              remaining < 0 ? 'Only the first 200 characters are kept' : '$remaining left',
              style: AppText.caption12.copyWith(
                color: remaining < 0 ? AppColors.criticalDeep : AppColors.inkFaint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
