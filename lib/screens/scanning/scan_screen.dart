import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../enum.dart';
import '../../locator.dart';
import '../../routes.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_chip.dart';
import '../../shared/components/headers.dart';
import '../../shared/components/pressable.dart';
import '../../shared/services/capture_service.dart';
import '../../shared/widgets/live_viewfinder.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../stores/pokedex_store.dart';
import '../../stores/scanning_store.dart';
import '../../theme.dart';

/// `Identify a plant`.
///
/// The shared [LiveViewfinder] on the rear camera. The shutter takes the
/// frame in app and hands it to the identification service; the preview
/// holds on that frame, blurred, while it is identified. With no camera to
/// show, the drawn stand-in returns and the shutter falls back to the
/// system camera.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ScanningStore _store = locator<ScanningStore>();
  late final LiveViewfinderController _viewfinder =
      LiveViewfinderController(capture: locator<CaptureService>());

  @override
  void initState() {
    super.initState();
    _store.resetScan();
  }

  @override
  void dispose() {
    _viewfinder.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    HapticFeedback.mediumImpact();
    // Without a camera to show, the shutter falls back to the system camera.
    final shot = await _viewfinder.shutter(fallback: _store.scanPlant);
    if (shot != null) await _store.identifyPhoto(shot);
    _showOutcome();
  }

  Future<void> _pickFromLibrary() async {
    await _store.selectImage();
    _showOutcome();
  }

  void _showOutcome() {
    if (!mounted) return;
    if (_store.hasMatch) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.scanResult);
    } else if (_store.showFailureSheet) {
      _showFailureSheet();
    }
  }

  void _showFailureSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x66000000),
      builder: (sheetContext) => _NoMatchSheet(
        onTryAgain: () {
          Navigator.of(sheetContext).pop();
          _store.resetScan();
        },
        onSearch: () {
          Navigator.of(sheetContext).pop();
          Navigator.of(context).pushReplacementNamed(AppRoutes.pokedex);
        },
        onSettings: () {
          Navigator.of(sheetContext).pop();
          _store.openSettings();
        },
        photoLibraryEnabled: _store.photoLibraryEnabled,
      ),
    ).whenComplete(() {
      // Back at the viewfinder: drop the frame that was being identified,
      // shot or picked, and let the preview run again.
      _store.resetScan();
      _viewfinder.resumePreview();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.darkOverlay,
      child: Scaffold(
        backgroundColor: AppColors.scanDark,
        body: Observer(
          builder: (context) {
            final busy = _store.isScanning || _store.isCapturing;
            // A photo picked from the library is held and blurred while it
            // is identified, just as a shot is.
            final picked = _store.capture;
            return Stack(
              fit: StackFit.expand,
              children: [
                LiveViewfinder(
                  controller: _viewfinder,
                  heldFile: picked != null && picked.source == 'gallery'
                      ? picked.file
                      : null,
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
                          title: 'Identify a plant',
                          onBack: () => Navigator.of(context).maybePop(),
                          leadingIcon: PgIcons.close,
                          foreground: Colors.white,
                          background: const Color(0x33FFFFFF),
                          trailing: ViewfinderTorchButton(
                            controller: _viewfinder,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.gutter,
                            AppSpacing.xxxl,
                            AppSpacing.gutter,
                            0,
                          ),
                          child: ViewfinderFrame(controller: _viewfinder),
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
                              busy ? 'Identifying…' : 'Point at a single leaf',
                              style: AppText.heading20.copyWith(
                                fontSize: 22.5,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Fill the frame with one healthy leaf in even '
                              'light — that gives the cleanest match.',
                              textAlign: TextAlign.center,
                              style: AppText.body15.copyWith(
                                fontSize: 15,
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (final target in ScanTarget.values) ...[
                                  if (target != ScanTarget.values.first)
                                    const SizedBox(width: AppSpacing.md),
                                  _TargetChip(
                                    label: target.label,
                                    selected: _store.target == target,
                                    onTap: () => _store.setTarget(target),
                                  ),
                                ],
                              ],
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
                              onTap: busy ? null : _pickFromLibrary,
                              semanticLabel: 'Choose from library',
                            ),
                            ViewfinderShutter(
                              busy: busy,
                              onTap: _scan,
                              icon: PgIcons.scan,
                              semanticLabel: 'Identify',
                            ),
                            ViewfinderAction(
                              icon: PgIcons.search,
                              onTap: () {
                                locator<PokedexStore>().clearFilters();
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed(AppRoutes.pokedex);
                              },
                              semanticLabel: 'Search manually',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TargetChip extends StatelessWidget {
  const _TargetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.95,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: AppRadius.pillR,
        ),
        child: Text(
          label,
          style: AppText.label13.copyWith(
            fontSize: 14,
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.66),
          ),
        ),
      ),
    );
  }
}

/// `We couldn't place this one` — the identification failure sheet.
class _NoMatchSheet extends StatelessWidget {
  const _NoMatchSheet({
    required this.onTryAgain,
    required this.onSearch,
    required this.onSettings,
    required this.photoLibraryEnabled,
  });

  final VoidCallback onTryAgain;
  final VoidCallback onSearch;
  final VoidCallback onSettings;
  final bool photoLibraryEnabled;

  @override
  Widget build(BuildContext context) {
    final store = locator<ScanningStore>();
    return Observer(
      builder: (context) {
        final offline = store.status == ScanStatus.offline;
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.ground,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.card),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.track,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Center(
                    child: Container(
                      width: 92,
                      height: 92,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: offline
                            ? AppColors.criticalTint
                            : AppColors.cautionTint,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: PgIcon(
                        offline ? PgIcons.wifiOff : PgIcons.searchAlert,
                        size: 40,
                        color: offline
                            ? AppColors.criticalDeep
                            : AppColors.cautionDeep,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    offline
                        ? 'No internet connection'
                        : "We couldn't place this one",
                    textAlign: TextAlign.center,
                    style: AppText.display40.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    offline
                        ? 'Identification needs a connection. Your photo is saved.'
                        : 'No match passed our confidence threshold. A clearer shot '
                              'of a single leaf usually fixes it.',
                    textAlign: TextAlign.center,
                    style: AppText.body15.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.cardR,
                      boxShadow: AppShadows.raised,
                    ),
                    child: const Column(
                      children: [
                        _Hint(
                          icon: PgIcons.sunLow,
                          label: 'Even, indirect light — avoid harsh backlight',
                        ),
                        SizedBox(height: AppSpacing.md),
                        _Hint(
                          icon: PgIcons.leaf,
                          label: 'One whole leaf filling most of the frame',
                        ),
                      ],
                    ),
                  ),
                  if (!photoLibraryEnabled) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EFED),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: Row(
                        children: [
                          const IconTile(
                            icon: PgIcons.lock,
                            tone: MetricStatus.neutral,
                            background: AppColors.surface,
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Photo library access is off',
                                  style: AppText.heading17.copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Turn it on to identify from a photo you already '
                                  'have.',
                                  style: AppText.body13.copyWith(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          AppButton.dark(
                            label: 'Settings',
                            expand: false,
                            height: 44,
                            fontSize: 14,
                            onPressed: onSettings,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.outline(
                          label: 'Search manually',
                          onPressed: onSearch,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppButton.primary(
                          label: 'Try again',
                          onPressed: onTryAgain,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.label});

  final PgIcons icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.neutralTint,
            borderRadius: BorderRadius.circular(15),
          ),
          child: PgIcon(icon, size: 22, color: AppColors.inkMuted),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Text(label, style: AppText.body15Ink.copyWith(fontSize: 15)),
        ),
      ],
    );
  }
}
