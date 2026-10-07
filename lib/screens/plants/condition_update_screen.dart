import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../domain/models/plant.dart';
import '../../domain/models/plant_condition_update.dart';
import '../../enum.dart';
import '../../locator.dart';
import '../../routes.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_chip.dart';
import '../../shared/components/app_surfaces.dart';
import '../../shared/components/app_text_field.dart';
import '../../shared/components/headers.dart';
import '../../shared/components/pressable.dart';
import '../../shared/services/capture_service.dart';
import '../../shared/widgets/live_viewfinder.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../shared/widgets/plant_artwork.dart';
import '../../stores/condition_update_store.dart';
import '../../theme.dart';
import '../../utils/date_format.dart';
import '../../utils/app_clock.dart';

/// The three-step condition update: capture the photo, review the framing,
/// then describe what you saw.
class ConditionUpdateScreen extends StatefulWidget {
  const ConditionUpdateScreen({super.key, required this.plant});

  final Plant plant;

  @override
  State<ConditionUpdateScreen> createState() => _ConditionUpdateScreenState();
}

class _ConditionUpdateScreenState extends State<ConditionUpdateScreen> {
  late final ConditionUpdateStore _store = locator<ConditionUpdateStore>()
    ..start(widget.plant);

  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _back() {
    if (_store.step == 0) {
      Navigator.of(context).maybePop();
    } else {
      _store.back();
    }
  }

  Future<void> _save() async {
    final ok = await _store.save();
    if (!ok || !mounted) return;
    HapticFeedback.mediumImpact();
    Navigator.of(
      context,
    ).pushReplacementNamed(AppRoutes.conditionConfirmed, arguments: _store);
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final onCamera = _store.step == 0;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: onCamera ? AppTheme.darkOverlay : AppTheme.lightOverlay,
          child: Scaffold(
            backgroundColor: onCamera ? AppColors.scanDark : AppColors.ground,
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.06, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey<int>(_store.step),
                child: switch (_store.step) {
                  0 => _CaptureStep(store: _store, onBack: _back),
                  1 => _ReviewStep(store: _store, onBack: _back),
                  _ => _DetailsStep(
                    store: _store,
                    notes: _notes,
                    onBack: _back,
                    onSave: _save,
                  ),
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Step 1 · Capture ───────────────────────────────────────────────────────

/// The shared [LiveViewfinder] — the same camera, frame, torch and shutter
/// as the identify screen — pointed at the whole plant.
class _CaptureStep extends StatefulWidget {
  const _CaptureStep({required this.store, required this.onBack});

  final ConditionUpdateStore store;
  final VoidCallback onBack;

  @override
  State<_CaptureStep> createState() => _CaptureStepState();
}

class _CaptureStepState extends State<_CaptureStep> {
  late final LiveViewfinderController _viewfinder =
      LiveViewfinderController(capture: locator<CaptureService>());

  ConditionUpdateStore get _store => widget.store;

  @override
  void dispose() {
    _viewfinder.dispose();
    super.dispose();
  }

  Future<void> _shoot() async {
    HapticFeedback.mediumImpact();
    // Without a camera to show, the shutter falls back to the system camera.
    final shot = await _viewfinder.shutter(fallback: () => _store.capture());
    if (shot == null) return;
    // The preview holds, blurred, while the photo uploads. If it could not
    // be kept the preview runs again so the keeper can retry.
    final kept = await _store.captureFromViewfinder(shot);
    if (!kept) await _viewfinder.resumePreview();
  }

  @override
  Widget build(BuildContext context) {
    final plant = _store.plant!;
    return Observer(
      builder: (context) {
        final busy = _store.isCapturing;
        return Stack(
          fit: StackFit.expand,
          children: [
            LiveViewfinder(
              controller: _viewfinder,
              standInGlyph: plant.species.glyph,
            ),
            if (busy) const ViewfinderSweep(),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.lg,
                      AppSpacing.gutter,
                      0,
                    ),
                    child: NavHeader(
                      title: 'Update plant condition',
                      onBack: widget.onBack,
                      leadingIcon: PgIcons.close,
                      foreground: Colors.white,
                      background: const Color(0x33FFFFFF),
                      progress: (step: 0, total: 3),
                      trailing: ViewfinderTorchButton(controller: _viewfinder),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.gutter,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: AppRadius.pillR,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.leaf,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const PgIcon(
                              PgIcons.leaf,
                              size: 24,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plant.nickname,
                                  style: AppText.heading17.copyWith(
                                    fontSize: 16.5,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  plant.daysSinceCondition == null
                                      ? 'First condition update'
                                      : 'Last update '
                                            '${AppDate.relativeDays(plant.daysSinceCondition!)}',
                                  style: AppText.body13.copyWith(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        AppSpacing.xxl,
                        AppSpacing.gutter,
                        0,
                      ),
                      child: ViewfinderFrame(controller: _viewfinder),
                    ),
                  ),
                  if (_store.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        AppSpacing.lg,
                        AppSpacing.gutter,
                        0,
                      ),
                      child: _CaptureError(
                        message: _store.errorMessage!,
                        showSettings: _store.needsSettings,
                        onSettings: _store.openSettings,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxl,
                      AppSpacing.xxl,
                      AppSpacing.xxl,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      children: [
                        Text(
                          busy
                              ? 'Saving your photo…'
                              : 'Take a photo of the whole plant',
                          textAlign: TextAlign.center,
                          style: AppText.heading20.copyWith(
                            fontSize: 22.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          "Keeps your plant's health history up to date. Same "
                          'angle as last time works best.',
                          textAlign: TextAlign.center,
                          style: AppText.body15.copyWith(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxxl,
                      0,
                      AppSpacing.xxxl,
                      AppSpacing.xl,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ViewfinderAction(
                          icon: PgIcons.image,
                          onTap: busy
                              ? null
                              : () => _store.capture(fromCamera: false),
                          semanticLabel: 'Choose from library',
                        ),
                        ViewfinderShutter(
                          busy: busy,
                          onTap: _shoot,
                          icon: PgIcons.camera,
                          semanticLabel: 'Take photo',
                        ),
                        // Nothing on the right; keeps the shutter centred.
                        ViewfinderAction.spacer,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A capture failure on the dark camera surface, with a way to Settings when
/// a permission was permanently refused.
class _CaptureError extends StatelessWidget {
  const _CaptureError({
    required this.message,
    required this.showSettings,
    required this.onSettings,
  });

  final String message;
  final bool showSettings;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Row(
        children: [
          const PgIcon(PgIcons.alertTriangle, size: 22, color: AppColors.leaf),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: AppText.body13.copyWith(
                fontSize: 13.5,
                color: Colors.white,
              ),
            ),
          ),
          if (showSettings) ...[
            const SizedBox(width: AppSpacing.sm),
            AppButton.primary(
              label: 'Settings',
              expand: false,
              height: 40,
              fontSize: 14,
              onPressed: onSettings,
            ),
          ],
        ],
      ),
    );
  }
}

/// Stands in for the capture while it is being taken, and if the file cannot
/// be read back.
class _ArtworkStandIn extends StatelessWidget {
  const _ArtworkStandIn({required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2B5230), Color(0xFF5E8B4A)],
            ),
          ),
        ),
        PlantArtwork(
          glyph: plant.species.glyph,
          showGround: false,
          tint: const Color(0xFF050D05),
          inset: 0.06,
        ),
      ],
    );
  }
}

// ── Step 2 · Review ────────────────────────────────────────────────────────

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.store, required this.onBack});

  final ConditionUpdateStore store;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final plant = store.plant!;
    return Observer(
      builder: (context) => SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.lg,
                AppSpacing.gutter,
                0,
              ),
              child: NavHeader(
                title: 'Review photo',
                onBack: onBack,
                progress: (step: 1, total: 3),
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.xl,
                  AppSpacing.gutter,
                  0,
                ),
                children: [
                  AspectRatio(
                    aspectRatio: 0.78,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // The stub capture has no file on disk; the drawn
                          // artwork stands in for it.
                          if (store.photo?.file.existsSync() ?? false)
                            Image.file(
                              store.photo!.file,
                              fit: BoxFit.cover,
                              errorBuilder: (context, _, _) =>
                                  _ArtworkStandIn(plant: plant),
                            )
                          else
                            _ArtworkStandIn(plant: plant),
                          Positioned(
                            top: AppSpacing.lg,
                            left: AppSpacing.lg,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.42),
                                borderRadius: AppRadius.pillR,
                              ),
                              child: Text(
                                'Today · '
                                '${AppDate.time(store.capturedAt ?? AppClock.now())}',
                                style: AppText.label13.copyWith(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: AppSpacing.lg,
                            right: AppSpacing.lg,
                            bottom: AppSpacing.lg,
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.32),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.tile,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const PgIcon(
                                    PgIcons.alertTriangle,
                                    size: 22,
                                    color: AppColors.leaf,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Text(
                                      store.framingNote,
                                      style: AppText.body15.copyWith(
                                        fontSize: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  EqualHeightRow(
                    children: [
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Compared with',
                              style: AppText.body15.copyWith(fontSize: 14),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              store.comparedWith,
                              style: AppText.heading20.copyWith(fontSize: 18.5),
                            ),
                          ],
                        ),
                      ),
                      SoftCard(
                        color: AppColors.softGreen,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Visible change',
                              style: AppText.body15.copyWith(
                                fontSize: 14,
                                color: AppColors.healthyDeep,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              store.visibleChange,
                              style: AppText.heading20.copyWith(
                                fontSize: 18.5,
                                color: AppColors.healthyDeep,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.lg,
                AppSpacing.gutter,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton.outline(
                      label: 'Retake',
                      onPressed: store.retake,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 3,
                    child: AppButton.primary(
                      label: 'Continue',
                      onPressed: store.next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 3 · Details ───────────────────────────────────────────────────────

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.store,
    required this.notes,
    required this.onBack,
    required this.onSave,
  });

  final ConditionUpdateStore store;
  final TextEditingController notes;
  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final plant = store.plant!;
    return Observer(
      builder: (context) => SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.lg,
                AppSpacing.gutter,
                0,
              ),
              child: NavHeader(
                title: 'Condition details',
                onBack: onBack,
                progress: (step: 3, total: 3),
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.xl,
                  AppSpacing.gutter,
                  0,
                ),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.tile + 4),
                        child: SizedBox(
                          width: 84,
                          height: 84,
                          child: PlantArtwork(
                            glyph: plant.species.glyph,
                            ground: plant.species.ground,
                            inset: 0.18,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'How is your plant doing?',
                              style: AppText.title28.copyWith(fontSize: 25),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              "${plant.nickname} · today's check-in",
                              style: AppText.body15.copyWith(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  for (final verdict in ConditionVerdict.values) ...[
                    _VerdictCard(
                      verdict: verdict,
                      selected: store.verdict == verdict,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        store.setVerdict(verdict);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          'What did you notice?',
                          style: AppText.title28.copyWith(fontSize: 21.5),
                        ),
                      ),
                      Text(
                        'Optional',
                        style: AppText.body15.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      for (final option in ConditionUpdate.observationOptions)
                        FilterChipPill(
                          label: option,
                          selected: store.observations.contains(option),
                          selectedColor: AppColors.ink,
                          selectedLabelColor: Colors.white,
                          onTap: () => store.toggleObservation(option),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text('Notes', style: AppText.title28.copyWith(fontSize: 21.5)),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    hint:
                        'Anything worth remembering — repotting, a move, a '
                        'new spot…',
                    controller: notes,
                    maxLines: 4,
                    minLines: 3,
                    onChanged: store.setNote,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.sm,
                AppSpacing.gutter,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  AppButton.primary(
                    label: 'Save update',
                    loading: store.isSaving,
                    onPressed: store.canSave ? onSave : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Your next check-in window opens in '
                    '${plant.schedule.checkInIntervalDays} days.',
                    style: AppText.body13.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerdictCard extends StatelessWidget {
  const _VerdictCard({
    required this.verdict,
    required this.selected,
    required this.onTap,
  });

  final ConditionVerdict verdict;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, tone) = switch (verdict) {
      ConditionVerdict.healthy => (PgIcons.check, MetricStatus.good),
      ConditionVerdict.concerns => (PgIcons.alertTriangle, MetricStatus.watch),
      ConditionVerdict.needsAttention => (
        PgIcons.alertCircle,
        MetricStatus.bad,
      ),
    };
    return Pressable(
      onTap: onTap,
      semanticLabel: verdict.title,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardR,
          border: Border.all(
            color: selected ? AppColors.ink : Colors.transparent,
            width: 1.8,
          ),
          boxShadow: selected ? null : AppShadows.raised,
        ),
        child: Row(
          children: [
            IconTile(icon: icon, tone: tone),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    verdict.title,
                    style: AppText.heading20.copyWith(fontSize: 18.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    verdict.subtitle,
                    style: AppText.body13.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
