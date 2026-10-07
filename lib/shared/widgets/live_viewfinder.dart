import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../enum.dart';
import '../../theme.dart';
import '../../utils/app_log.dart';
import '../components/app_button.dart';
import '../components/pressable.dart';
import '../services/capture_service.dart';
import 'pg_icon.dart';
import 'plant_artwork.dart';

/// The in-app camera, shared by the identify screen and the condition
/// check-in so both feel the same: one controller for the rear camera, one
/// full-bleed feed with the blur while a frame is held, and the same frame,
/// torch, shutter, actions and "camera off" notice drawn over it.

/// Where the viewfinder's camera stands.
enum ViewfinderState {
  /// Asking for access, or opening the camera.
  starting,
  live,

  /// Refused this time — the shutter asks again.
  denied,

  /// Refused for good — the shutter opens Settings.
  blocked,

  /// No camera, or it would not open.
  unavailable,
}

/// Owns the rear camera for a [LiveViewfinder]: access, opening and closing
/// around the app lifecycle, the torch, the shutter and the held frame.
///
/// Create one per screen and dispose it with the screen; [LiveViewfinder]
/// binds to it for as long as it is on screen.
class LiveViewfinderController extends ChangeNotifier {
  LiveViewfinderController({required this._capture});

  final CaptureService _capture;

  CameraController? _camera;
  ViewfinderState _state = ViewfinderState.starting;
  bool _torchOn = false;
  bool _opening = false;
  bool _disposed = false;

  CameraController? get camera => _camera;
  ViewfinderState get state => _state;
  bool get torchOn => _torchOn;
  bool get isLive => _state == ViewfinderState.live && _camera != null;

  /// True while the preview is paused on the frame that was just taken.
  bool get isHeld => _camera?.value.isPreviewPaused ?? false;

  /// Asks for access (unless [prompt] is false, for a resume from Settings,
  /// where prompting would reopen the dialog as it closes) and opens the
  /// rear camera.
  Future<void> open({bool prompt = true}) async {
    if (_opening || _camera != null || _disposed) return;
    _opening = true;
    try {
      final access = await _capture.cameraAccess(prompt: prompt);
      if (_disposed) return;
      if (access != CameraAccess.granted) {
        _set(access == CameraAccess.blocked
            ? ViewfinderState.blocked
            : ViewfinderState.denied);
        return;
      }

      final cameras = await availableCameras();
      final rear = cameras
              .where((c) => c.lensDirection == CameraLensDirection.back)
              .firstOrNull ??
          cameras.firstOrNull;
      if (rear == null) {
        _set(ViewfinderState.unavailable);
        return;
      }

      // 1080p keeps the long side inside the upload cap without re-encoding.
      final camera = CameraController(
        rear,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      try {
        await camera.initialize();
      } catch (_) {
        await camera.dispose();
        rethrow;
      }
      // Backgrounded (or gone) while opening — the resume opens it again.
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (_disposed ||
          (lifecycle != null && lifecycle != AppLifecycleState.resumed)) {
        await camera.dispose();
        return;
      }
      _camera = camera;
      _set(ViewfinderState.live);
      await _applyTorch();
    } on CameraException catch (e) {
      AppLog.w('viewfinder unavailable: ${e.code}', name: 'camera');
      _set(e.code.contains('AccessDenied')
          ? ViewfinderState.denied
          : ViewfinderState.unavailable);
    } finally {
      _opening = false;
    }
  }

  /// Releases the camera. The next [open] starts a fresh preview.
  void close() {
    final camera = _camera;
    if (camera == null) return;
    _camera = null;
    _set(ViewfinderState.starting);
    camera.dispose();
  }

  Future<void> toggleTorch() async {
    _torchOn = !_torchOn;
    _notify();
    await _applyTorch();
  }

  /// Matches the lamp to the torch button. Off rather than auto otherwise,
  /// so the shutter never fires a flash the keeper did not ask for.
  Future<void> _applyTorch() async {
    final camera = _camera;
    if (camera == null) return;
    try {
      await camera.setFlashMode(_torchOn ? FlashMode.torch : FlashMode.off);
    } on CameraException catch (e) {
      AppLog.w('torch unavailable: ${e.code}', name: 'camera');
      if (_torchOn) {
        _torchOn = false;
        _notify();
      }
    }
  }

  /// What the shutter does depends on where the camera stands: nothing
  /// while it opens, another prompt when refused, Settings when blocked,
  /// [fallback] (the system camera) when there is no camera to show, and
  /// the frame itself when live. Returns the frame only in that last case.
  Future<File?> shutter({Future<void> Function()? fallback}) async {
    switch (_state) {
      case ViewfinderState.starting:
        return null;
      case ViewfinderState.denied:
        await open();
        return null;
      case ViewfinderState.blocked:
        await _capture.openSettings();
        return null;
      case ViewfinderState.unavailable:
        await fallback?.call();
        return null;
      case ViewfinderState.live:
        return takePicture();
    }
  }

  /// Takes the frame and holds the preview on it. Null while a frame is
  /// already being taken or held.
  Future<File?> takePicture() async {
    final camera = _camera;
    if (camera == null ||
        camera.value.isTakingPicture ||
        camera.value.isPreviewPaused) {
      return null;
    }
    final XFile shot;
    try {
      shot = await camera.takePicture();
    } on CameraException catch (e, stack) {
      AppLog.e('shutter failed', name: 'camera', error: e, stackTrace: stack);
      return null;
    }
    // Hold on the frame while it is used; if the preview will not pause it
    // just keeps running.
    await camera.pausePreview().catchError(
      (_) {},
      test: (e) => e is CameraException,
    );
    _notify();
    return File(shot.path);
  }

  /// Lets the preview run again after a held frame was not kept.
  Future<void> resumePreview() async {
    final camera = _camera;
    if (camera == null || !camera.value.isPreviewPaused) return;
    try {
      await camera.resumePreview();
    } on CameraException catch (_) {
      // Closed underneath us; the next open starts a fresh preview.
    }
    _notify();
  }

  void _set(ViewfinderState value) {
    if (_state == value) return;
    _state = value;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    close();
    _disposed = true;
    super.dispose();
  }
}

/// The rear camera, full-bleed, with the stand-in while it starts and the
/// blur while a frame is held.
///
/// Binds to [controller] for its lifetime: opens the camera on mount,
/// releases it when the app goes to the background, reopens it on resume,
/// and releases it again when removed.
class LiveViewfinder extends StatefulWidget {
  const LiveViewfinder({
    super.key,
    required this.controller,
    this.standInGlyph = PlantGlyph.monstera,
  });

  final LiveViewfinderController controller;

  /// Drawn on the stand-in when there is no camera to show.
  final PlantGlyph standInGlyph;

  @override
  State<LiveViewfinder> createState() => _LiveViewfinderState();
}

class _LiveViewfinderState extends State<LiveViewfinder>
    with WidgetsBindingObserver {
  LiveViewfinderController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_rebuild);
    _controller.open();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_rebuild);
    _controller.close();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        // The camera cannot be held while the app is in the background, so
        // it is released here and reopened on the way back.
        _controller.close();
      case AppLifecycleState.resumed:
        // Only read access on resume: the permission dialog itself pauses
        // the app, and prompting from here would reopen it as it closes.
        _controller.open(prompt: false);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final camera = _controller.camera;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: camera != null && _controller.isLive
          ? _Feed(key: ValueKey(camera), controller: camera)
          : _StandIn(
              glyph: widget.standInGlyph,
              showArtwork: _controller.state == ViewfinderState.unavailable,
            ),
    );
  }
}

/// The camera feed, cropped to fill the screen.
///
/// Once the shutter has taken a frame the preview is paused on it, and this
/// widget blurs the held frame so it reads as "being used" rather than as a
/// stalled viewfinder. The blur follows the controller's own
/// `isPreviewPaused`, so it can never be out of step with the pause.
class _Feed extends StatelessWidget {
  const _Feed({super.key, required this.controller});

  final CameraController controller;

  static const double _heldBlur = 14;

  @override
  Widget build(BuildContext context) {
    // Reported landscape; the screens are portrait-locked, so swap the sides.
    final size = controller.value.previewSize;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.scanDark),
        if (size != null)
          ValueListenableBuilder<CameraValue>(
            valueListenable: controller,
            builder: (context, value, preview) {
              // Eases in as the frame is held and back out when the preview
              // resumes, instead of snapping.
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(end: value.isPreviewPaused ? 1 : 0),
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) {
                  if (t == 0) return child!;
                  return ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: _heldBlur * t,
                      sigmaY: _heldBlur * t,
                    ),
                    child: ColorFiltered(
                      // A touch darker as well, so the copy over it sits on
                      // a calmer ground.
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.22 * t),
                        BlendMode.srcOver,
                      ),
                      child: child,
                    ),
                  );
                },
                child: preview,
              );
            },
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: size.height,
                  height: size.width,
                  child: CameraPreview(controller),
                ),
              ),
            ),
          ),
        // Scrims keep the header, copy and controls legible over any scene.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.2, 0.5, 0.72, 1],
              colors: [
                Color(0x8C000000),
                Color(0x00000000),
                Color(0x00060E08),
                Color(0xB3060E08),
                Color(0xF2060E08),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The drawn viewfinder, shown while the camera starts or when there is none.
class _StandIn extends StatelessWidget {
  const _StandIn({required this.glyph, required this.showArtwork});

  final PlantGlyph glyph;
  final bool showArtwork;

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
              colors: [Color(0xFF1B3A22), Color(0xFF13291A), Color(0xFF060E08)],
            ),
          ),
        ),
        if (showArtwork)
          Positioned(
            left: -60,
            bottom: 60,
            width: 520,
            height: 520,
            child: PlantArtwork(
              glyph: glyph,
              showGround: false,
              tint: const Color(0xFF040B05),
              opacity: 0.94,
            ),
          ),
      ],
    );
  }
}

// ── Chrome drawn over the feed ─────────────────────────────────────────────

/// The lime corner frame. While access is refused it carries the
/// "camera off" notice, whose button prompts again or opens Settings.
class ViewfinderFrame extends StatelessWidget {
  const ViewfinderFrame({super.key, required this.controller});

  final LiveViewfinderController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => CustomPaint(
        painter: const _CornerFramePainter(),
        child: SizedBox.expand(
          child: switch (controller.state) {
            ViewfinderState.denied ||
            ViewfinderState.blocked =>
              _CameraOffNotice(
                blocked: controller.state == ViewfinderState.blocked,
                onPressed: () => controller.shutter(),
              ),
            _ => null,
          },
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

/// Sits inside the frame when camera access has been refused.
class _CameraOffNotice extends StatelessWidget {
  const _CameraOffNotice({required this.blocked, required this.onPressed});

  final bool blocked;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.tile),
              ),
              child: const PgIcon(
                PgIcons.camera,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Camera access is off',
              style: AppText.heading20.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              blocked
                  ? 'Turn it on in Settings to take plant photos through the '
                        'viewfinder.'
                  : 'Allow camera access to take plant photos through the '
                        'viewfinder.',
              textAlign: TextAlign.center,
              style: AppText.body15.copyWith(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton.primary(
              label: blocked ? 'Open Settings' : 'Allow camera',
              expand: false,
              height: 48,
              fontSize: 15,
              onPressed: onPressed,
            ),
          ],
        ),
      ),
    );
  }
}

/// The torch toggle for the header.
class ViewfinderTorchButton extends StatelessWidget {
  const ViewfinderTorchButton({super.key, required this.controller});

  final LiveViewfinderController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => CircleIconButton(
        icon: PgIcons.flash,
        onPressed: controller.toggleTorch,
        background:
            controller.torchOn ? AppColors.leaf : const Color(0x33FFFFFF),
        foreground: controller.torchOn ? AppColors.ink : Colors.white,
        elevated: false,
        semanticLabel: 'Torch',
      ),
    );
  }
}

/// The green line sweeping the frame while a photo is being worked on.
class ViewfinderSweep extends StatefulWidget {
  const ViewfinderSweep({super.key});

  @override
  State<ViewfinderSweep> createState() => _ViewfinderSweepState();
}

class _ViewfinderSweepState extends State<ViewfinderSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sweep,
      builder: (context, _) => Align(
        alignment: Alignment(0, _sweep.value * 2 - 1),
        child: Container(
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
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
    );
  }
}

/// The big round shutter. Shrinks into a spinner while [busy].
class ViewfinderShutter extends StatelessWidget {
  const ViewfinderShutter({
    super.key,
    required this.busy,
    required this.onTap,
    required this.icon,
    required this.semanticLabel,
  });

  final bool busy;
  final VoidCallback onTap;
  final PgIcons icon;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: busy ? null : onTap,
      scale: 0.9,
      semanticLabel: semanticLabel,
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
              : Center(child: PgIcon(icon, size: 30, color: AppColors.ink)),
        ),
      ),
    );
  }
}

/// A square action beside the shutter (library, search). A null [onTap]
/// renders it disabled; [ViewfinderAction.spacer] keeps the shutter centred
/// when one side has no action.
class ViewfinderAction extends StatelessWidget {
  const ViewfinderAction({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  static const double size = 58;

  /// An empty slot the width of an action.
  static const Widget spacer = SizedBox(width: size, height: size);

  final PgIcons icon;
  final VoidCallback? onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.92,
      semanticLabel: semanticLabel,
      child: Container(
        width: size,
        height: size,
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
