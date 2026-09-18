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
import '../../shared/widgets/pg_icon.dart';
import '../../shared/widgets/plant_artwork.dart';
import '../../stores/pokedex_store.dart';
import '../../stores/scanning_store.dart';
import '../../theme.dart';

/// `Identify a plant`.
///
/// The viewfinder is a rendered stand-in — no camera stream is attached and no
/// image recognition runs on device. Capturing calls the identification
/// service, which returns a scripted match in this build.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  final ScanningStore _store = locator<ScanningStore>();

  late final AnimationController _sweep;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _store.resetScan();
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    HapticFeedback.mediumImpact();
    await _store.scanPlant();
    if (!mounted) return;
    if (_store.hasMatch) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.scanResult);
    } else {
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
        photoLibraryEnabled: _store.photoLibraryEnabled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.darkOverlay,
      child: Scaffold(
        backgroundColor: AppColors.scanDark,
        body: Observer(
          builder: (context) => Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1B3A22),
                      Color(0xFF13291A),
                      Color(0xFF060E08),
                    ],
                  ),
                ),
              ),
              const Positioned(
                left: -60,
                bottom: 60,
                width: 520,
                height: 520,
                child: PlantArtwork(
                  glyph: PlantGlyph.monstera,
                  showGround: false,
                  tint: Color(0xFF040B05),
                  opacity: 0.94,
                ),
              ),
              if (_store.isScanning)
                AnimatedBuilder(
                  animation: _sweep,
                  builder: (context, _) => Align(
                    alignment: Alignment(0, _sweep.value * 2 - 1),
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxxl,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.leaf.withValues(alpha: 0),
                            AppColors.leaf,
                            AppColors.leaf.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
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
                        title: 'Identify a plant',
                        onBack: () => Navigator.of(context).maybePop(),
                        leadingIcon: PgIcons.close,
                        foreground: Colors.white,
                        background: const Color(0x33FFFFFF),
                        trailing: CircleIconButton(
                          icon: PgIcons.flash,
                          onPressed: _store.toggleTorch,
                          background: _store.torchOn
                              ? AppColors.leaf
                              : const Color(0x33FFFFFF),
                          foreground: _store.torchOn
                              ? AppColors.ink
                              : Colors.white,
                          elevated: false,
                          semanticLabel: 'Torch',
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.gutter,
                          AppSpacing.xxxl,
                          AppSpacing.gutter,
                          0,
                        ),
                        child: CustomPaint(
                          painter: _CornerFramePainter(),
                          child: SizedBox.expand(),
                        ),
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
                            _store.isScanning
                                ? 'Identifying…'
                                : 'Point at a single leaf',
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
                          _RoundAction(
                            icon: PgIcons.image,
                            onTap: () async {
                              await _store.selectImage();
                              if (!context.mounted) return;
                              if (_store.hasMatch) {
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed(AppRoutes.scanResult);
                              } else {
                                _showFailureSheet();
                              }
                            },
                            semanticLabel: 'Choose from library',
                          ),
                          _ShutterButton(busy: _store.isScanning, onTap: _scan),
                          _RoundAction(
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
          ),
        ),
      ),
    );
  }
}

class _CornerFramePainter extends CustomPainter {
  const _CornerFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.leaf
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round;

    const r = 26.0;
    const arm = 66.0;
    final corners = [
      // (startX, startY, cornerX, cornerY, endX, endY)
      [0.0, r + arm, 0.0, 0.0, r + arm, 0.0],
      [size.width - r - arm, 0.0, size.width, 0.0, size.width, r + arm],
      [
        size.width,
        size.height - r - arm,
        size.width,
        size.height,
        size.width - r - arm,
        size.height,
      ],
      [r + arm, size.height, 0.0, size.height, 0.0, size.height - r - arm],
    ];
    for (final c in corners) {
      final path = Path()
        ..moveTo(c[0], c[1])
        ..quadraticBezierTo(c[2], c[3], c[4], c[5]);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CornerFramePainter oldDelegate) => false;
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

class _RoundAction extends StatelessWidget {
  const _RoundAction({
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
      scale: 0.92,
      semanticLabel: semanticLabel,
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

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: busy ? null : onTap,
      scale: 0.9,
      semanticLabel: 'Identify',
      child: Container(
        width: 96,
        height: 96,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.16),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: busy ? 62 : 76,
          height: busy ? 62 : 76,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.leaf,
          ),
          child: busy
              ? const Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
                  ),
                )
              : const Center(
                  child: PgIcon(PgIcons.scan, size: 30, color: AppColors.ink),
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
    required this.photoLibraryEnabled,
  });

  final VoidCallback onTryAgain;
  final VoidCallback onSearch;
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
                            onPressed: () => Navigator.of(context).pop(),
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
