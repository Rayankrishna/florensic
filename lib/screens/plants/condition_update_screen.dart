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

class _CaptureStep extends StatelessWidget {
  const _CaptureStep({required this.store, required this.onBack});

  final ConditionUpdateStore store;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final plant = store.plant!;
    return Observer(
      builder: (context) => Stack(
        fit: StackFit.expand,
        children: [
          const _CameraSurface(),
          Positioned(
            right: -70,
            bottom: 120,
            width: 380,
            height: 420,
            child: PlantArtwork(
              glyph: plant.species.glyph,
              showGround: false,
              tint: const Color(0xFF040A04),
              opacity: 0.92,
            ),
          ),
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
                    onBack: onBack,
                    leadingIcon: PgIcons.close,
                    foreground: Colors.white,
                    background: const Color(0x33FFFFFF),
                    progress: (step: 0, total: 3),
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
                const SizedBox(height: AppSpacing.xxl),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.gutter,
                    ),
                    child: CustomPaint(
                      painter: _FramePainter(),
                      child: SizedBox.expand(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.xxl,
                    AppSpacing.xxl,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Take a photo of the whole plant',
                        textAlign: TextAlign.center,
                        style: AppText.heading20.copyWith(
                          fontSize: 21.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        "Keeps your plant's health history up to date. Same angle "
                        'as last time works best.',
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
                    AppSpacing.gutter,
                    0,
                    AppSpacing.gutter,
                    AppSpacing.xl,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CameraChip(
                        icon: PgIcons.image,
                        onTap: store.capture,
                        semanticLabel: 'Choose from library',
                      ),
                      _Shutter(busy: store.isCapturing, onTap: store.capture),
                      _CameraChip(
                        icon: PgIcons.refresh,
                        onTap: () {},
                        semanticLabel: 'Flip camera',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraSurface extends StatelessWidget {
  const _CameraSurface();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF14301B), Color(0xFF0C1B10), Color(0xFF060E08)],
          stops: [0, 0.55, 1],
        ),
      ),
    );
  }
}

/// A capture frame with two lime corner accents, as the design shows.
class _FramePainter extends CustomPainter {
  const _FramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(AppRadius.card),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final accent = Paint()
      ..color = AppColors.leaf
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;

    const r = AppRadius.card;
    const arm = 74.0;
    final topLeft = Path()
      ..moveTo(0, r + arm)
      ..lineTo(0, r)
      ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
      ..lineTo(r + arm, 0);
    canvas.drawPath(topLeft, accent);

    final bottomRight = Path()
      ..moveTo(size.width, size.height - r - arm)
      ..lineTo(size.width, size.height - r)
      ..arcToPoint(
        Offset(size.width - r, size.height),
        radius: const Radius.circular(r),
      )
      ..lineTo(size.width - r - arm, size.height);
    canvas.drawPath(bottomRight, accent);
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) => false;
}

class _CameraChip extends StatelessWidget {
  const _CameraChip({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  final PgIcons icon;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      scale: 0.92,
      child: Container(
        width: 58,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.tile),
        ),
        child: PgIcon(icon, size: 24, color: Colors.white),
      ),
    );
  }
}

class _Shutter extends StatelessWidget {
  const _Shutter({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: busy ? null : onTap,
      semanticLabel: 'Take photo',
      scale: 0.9,
      child: Container(
        width: 84,
        height: 84,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.16),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: busy ? 56 : 68,
          height: busy ? 56 : 68,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
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
