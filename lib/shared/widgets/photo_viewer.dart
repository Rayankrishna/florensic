import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme.dart';
import '../components/app_button.dart';
import 'pg_icon.dart';

/// One photo the viewer can show.
///
/// The viewer does not know where pictures come from: [image] draws the
/// photo at a given fit, so the page can show it whole (`contain`) and the
/// hero flight can show it cropped (`cover`) while its shape morphs.
class ViewerPhoto {
  const ViewerPhoto({
    required this.heroTag,
    required this.image,
    this.title,
    this.subtitle,
    this.aspectRatio,
    this.probe,
    this.originRadius = AppRadius.tile,
  });

  /// The tag of the [Hero] around this photo on the screen it was opened
  /// from, so it grows out of that spot and shrinks back into it — the same
  /// flight a plant card makes into its page.
  final Object heroTag;
  final Widget Function(BoxFit fit) image;

  /// e.g. "Taken 13 Nov" and "Check-in".
  final String? title;
  final String? subtitle;

  /// Width over height, when known.
  final double? aspectRatio;

  /// An image whose decoded size is the photo's true shape. It corrects
  /// [aspectRatio] when that is missing or wrong (a rotated original).
  final ImageProvider? probe;

  /// Corner radius of the photo's spot, so the corners morph during the
  /// flight instead of jumping.
  final double originRadius;
}

/// What the photo route is pushed with.
class PhotoViewerArgs {
  const PhotoViewerArgs({
    required this.photos,
    this.initialIndex = 0,
    this.partnerTags = const {},
  });

  final List<ViewerPhoto> photos;
  final int initialIndex;

  /// Hero tags of the spots known to be on screen behind the viewer. A
  /// photo whose own spot is among them flies home to it; any other photo
  /// flies into the spot the viewer was opened from, rather than fading
  /// out in place.
  final Set<Object> partnerTags;
}

/// Photos, full screen.
///
/// The tapped photo flies in from where it sat and back on close. Swipe
/// sideways between photos, pinch or double-tap to zoom, and drag down to
/// put it back. The page is the app's own light ground — no black stage.
class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({
    super.key,
    required this.photos,
    this.initialIndex = 0,
    this.partnerTags = const {},
  });

  final List<ViewerPhoto> photos;
  final int initialIndex;
  final Set<Object> partnerTags;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _pages = PageController(initialPage: _initial);
  late int _index = _initial;

  /// A zoomed photo pans instead of paging.
  bool _zoomed = false;

  /// 0 at rest, rising to 1 as a drag down nears closing.
  double _dismiss = 0;

  /// Fingers on the glass. A second one means a pinch is starting: paging
  /// steps aside, so a pinch led by one finger zooms instead of turning the
  /// page. A set rather than a count, so a lost up event cannot wedge it.
  final Set<int> _fingers = {};

  /// Stand-in tags for a page whose own tag the current page has borrowed,
  /// so two heroes never share one.
  final Map<int, Object> _spareTags = {};

  int get _initial =>
      widget.initialIndex.clamp(0, math.max(0, widget.photos.length - 1));

  ViewerPhoto get _origin => widget.photos[_initial];

  /// Whether the page on screen flies to its own spot, or — when that spot
  /// is not showing behind the viewer — to the one it was opened from.
  bool get _flyHome =>
      widget.partnerTags.contains(widget.photos[_index].heroTag);

  Object get _currentTag =>
      _flyHome ? widget.photos[_index].heroTag : _origin.heroTag;

  Object _tagFor(int i) {
    if (i == _index) return _currentTag;
    final own = widget.photos[i].heroTag;
    return own == _currentTag ? (_spareTags[i] ??= Object()) : own;
  }

  double _radiusFor(int i) => i == _index && !_flyHome
      ? _origin.originRadius
      : widget.photos[i].originRadius;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).maybePop();

  void _fingerDown(PointerDownEvent event) {
    if (_fingers.add(event.pointer) && _fingers.length == 2) setState(() {});
  }

  void _fingerUp(PointerEvent event) {
    if (_fingers.remove(event.pointer) && _fingers.length == 1) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final current = photos[_index];
    final chrome = (1 - _dismiss * 2.2).clamp(0.0, 1.0);
    final count = photos.length > 1 ? '${_index + 1} of ${photos.length}' : null;
    final subtitle = [?current.subtitle, ?count].join(' · ');
    final paging = !_zoomed && _fingers.length < 2;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.lightOverlay,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: AppColors.ground.withValues(alpha: 1 - _dismiss),
                ),
              ),
            ),
            Listener(
              onPointerDown: _fingerDown,
              onPointerUp: _fingerUp,
              onPointerCancel: _fingerUp,
              child: PageView.builder(
                controller: _pages,
                physics: paging
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: photos.length,
                onPageChanged: (i) => setState(() {
                  _index = i;
                  _zoomed = false;
                }),
                itemBuilder: (context, i) => _ViewerPage(
                  photo: photos[i],
                  heroTag: _tagFor(i),
                  originRadius: _radiusFor(i),
                  onZoomChanged: (zoomed) {
                    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
                  },
                  onDismissProgress: (p) {
                    if (p != _dismiss) setState(() => _dismiss = p);
                  },
                  onDismiss: _close,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: chrome < 0.5,
                child: Opacity(
                  opacity: chrome,
                  child: DecoratedBox(
                    // The ground behind the bar keeps it, and the status bar
                    // icons, readable over a zoomed photo. Over the plain
                    // backdrop it cannot be seen.
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0, 0.7, 1],
                        colors: [
                          AppColors.ground,
                          AppColors.ground.withValues(alpha: 0.9),
                          AppColors.ground.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.gutter,
                          AppSpacing.md,
                          AppSpacing.gutter,
                          AppSpacing.lg,
                        ),
                        child: Row(
                          children: [
                            CircleIconButton(
                              icon: PgIcons.close,
                              size: 44,
                              onPressed: _close,
                              semanticLabel: 'Close photo',
                            ),
                            Expanded(
                              // Zoomed in, the photo is the point; the close
                              // button stays.
                              child: AnimatedOpacity(
                                opacity: _zoomed ? 0 : 1,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                child: Column(
                                  children: [
                                    if (current.title != null)
                                      Text(
                                        current.title!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.heading17
                                            .copyWith(fontSize: 16),
                                      ),
                                    if (subtitle.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.body13
                                            .copyWith(fontSize: 13),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            // Balances the close button so the title centres.
                            const SizedBox(width: 44),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One photo: zoomable, and dragged down to close.
class _ViewerPage extends StatefulWidget {
  const _ViewerPage({
    required this.photo,
    required this.heroTag,
    required this.originRadius,
    required this.onZoomChanged,
    required this.onDismissProgress,
    required this.onDismiss,
  });

  final ViewerPhoto photo;

  /// The tag this page flies under — its own, or the spot the viewer was
  /// opened from when its own is not on screen.
  final Object heroTag;

  /// Corner radius of whichever spot [heroTag] belongs to.
  final double originRadius;
  final ValueChanged<bool> onZoomChanged;
  final ValueChanged<double> onDismissProgress;
  final VoidCallback onDismiss;

  @override
  State<_ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<_ViewerPage>
    with TickerProviderStateMixin {
  /// Corner radius of the photo on this page.
  static const double _radius = AppRadius.tile;

  /// How far down a drag must travel, or how fast, to close.
  static const double _closeDistance = 140;
  static const double _closeVelocity = 900;

  /// The drag distance at which the backdrop has fully faded.
  static const double _fadeDistance = 280;

  final TransformationController _transform = TransformationController();
  late final AnimationController _zoomMotion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..addListener(_applyZoomMotion);
  late final AnimationController _dragMotion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  )..addListener(_applyDragMotion);
  Animation<Matrix4>? _zoomTween;
  Animation<double>? _dragTween;

  late double? _aspect = widget.photo.aspectRatio;
  ImageStream? _probeStream;
  ImageStreamListener? _probeListener;

  /// The route's entrance, while a shape correction waits for it to end.
  Animation<double>? _entrance;
  double? _pendingAspect;

  Offset _doubleTapAt = Offset.zero;
  bool _zoomed = false;

  /// A single-finger drag down that started unzoomed — the close gesture.
  bool _dragging = false;
  double _drag = 0;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveShape();
  }

  @override
  void dispose() {
    _stopProbe();
    _entrance?.removeStatusListener(_onEntrance);
    _transform
      ..removeListener(_onTransform)
      ..dispose();
    _zoomMotion.dispose();
    _dragMotion.dispose();
    super.dispose();
  }

  // ── Shape ────────────────────────────────────────────────────────────────

  /// Reads the photo's real proportions off the decoded image. A copy that
  /// is already on screen is in the image cache and answers at once.
  void _resolveShape() {
    final probe = widget.photo.probe;
    if (probe == null || _probeStream != null) return;
    final stream = probe.resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener(
      (info, synchronousCall) {
        final w = info.image.width;
        final h = info.image.height;
        info.dispose();
        _stopProbe();
        if (!mounted || w <= 0 || h <= 0) return;
        final shape = w / h;
        final known = _aspect;
        // Only move when it is really different: a rounding slip is not
        // worth an animation.
        if (known != null && (shape - known).abs() / shape <= 0.02) return;
        // A cached image answers inside addListener, before the first build
        // and before the flight measures where to land — set it outright.
        if (synchronousCall) {
          _aspect = shape;
        } else {
          _applyShape(shape);
        }
      },
      onError: (_, _) => _stopProbe(),
    );
    _probeStream = stream;
    _probeListener = listener;
    stream.addListener(listener);
  }

  void _stopProbe() {
    final stream = _probeStream;
    final listener = _probeListener;
    if (stream != null && listener != null) stream.removeListener(listener);
    _probeListener = null;
  }

  /// A late answer reshapes the frame — but not while the photo is still
  /// flying in: the flight lands on the box it measured at take-off, so a
  /// change mid-air would snap at landing. It waits and reshapes in place.
  void _applyShape(double shape) {
    final entrance = ModalRoute.of(context)?.animation;
    if (entrance == null || entrance.isCompleted) {
      setState(() => _aspect = shape);
      return;
    }
    _pendingAspect = shape;
    _entrance ??= entrance..addStatusListener(_onEntrance);
  }

  void _onEntrance(AnimationStatus status) {
    if (!status.isCompleted) return;
    _entrance?.removeStatusListener(_onEntrance);
    _entrance = null;
    final shape = _pendingAspect;
    _pendingAspect = null;
    if (mounted && shape != null) setState(() => _aspect = shape);
  }

  // ── Zoom ─────────────────────────────────────────────────────────────────

  void _onTransform() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed == _zoomed) return;
    setState(() => _zoomed = zoomed);
    widget.onZoomChanged(zoomed);
  }

  void _applyZoomMotion() {
    final tween = _zoomTween;
    if (tween != null) _transform.value = tween.value;
  }

  /// Double tap: 2.5× around the tapped point, or back to whole.
  void _toggleZoom() {
    final Matrix4 target;
    if (_zoomed) {
      target = Matrix4.identity();
    } else {
      const s = 2.5;
      final p = _doubleTapAt;
      // Scales by s while keeping the tapped point where it is.
      target = Matrix4.identity()
        ..setEntry(0, 0, s)
        ..setEntry(1, 1, s)
        ..setEntry(0, 3, -p.dx * (s - 1))
        ..setEntry(1, 3, -p.dy * (s - 1));
    }
    _zoomTween = Matrix4Tween(begin: _transform.value, end: target).animate(
      CurvedAnimation(parent: _zoomMotion, curve: Curves.easeOutCubic),
    );
    _zoomMotion.forward(from: 0);
  }

  // ── Drag down to close ───────────────────────────────────────────────────

  void _report() =>
      widget.onDismissProgress((_drag / _fadeDistance).clamp(0.0, 1.0));

  void _applyDragMotion() {
    final tween = _dragTween;
    if (tween == null) return;
    setState(() => _drag = tween.value);
    _report();
  }

  void _onStart(ScaleStartDetails details) {
    // A new touch takes over from a double-tap zoom still in motion: it
    // stops where it is, so the pinch or pan continues from what is on
    // screen instead of fighting the animation. Barely zoomed counts as
    // whole, so the close drag and paging start clean.
    if (_zoomMotion.isAnimating) {
      _zoomMotion.stop();
      if (!_zoomed) _transform.value = Matrix4.identity();
    }
    _dragging = !_zoomed && details.pointerCount == 1;
    if (_dragging) _dragMotion.stop();
  }

  void _onUpdate(ScaleUpdateDetails details) {
    if (!_dragging) return;
    setState(() => _drag = math.max(0, _drag + details.focalPointDelta.dy));
    _report();
  }

  void _onEnd(ScaleEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    // The recognizer also ends a gesture when a finger is added. Fingers
    // still down mean the drag is becoming a pinch, not letting go.
    if (details.pointerCount > 0) {
      _settleBack();
      return;
    }
    if (_drag > _closeDistance ||
        details.velocity.pixelsPerSecond.dy > _closeVelocity) {
      widget.onDismiss();
      return;
    }
    _settleBack();
  }

  void _settleBack() {
    if (_drag == 0) return;
    _dragTween = Tween<double>(begin: _drag, end: 0).animate(
      CurvedAnimation(parent: _dragMotion, curve: Curves.easeOutCubic),
    );
    _dragMotion.forward(from: 0);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  Widget _shuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    // Both ways the photo flies cropped to the moving frame, with its
    // corners easing between its spot and here. `animation` runs 0 at the
    // spot to 1 on this page, whichever way the flight goes.
    return AnimatedBuilder(
      animation: animation,
      child: widget.photo.image(BoxFit.cover),
      builder: (context, child) => ClipRRect(
        borderRadius: BorderRadius.circular(
          lerpDouble(widget.originRadius, _radius, animation.value)!,
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    final shrink = 1 - (_drag / 900).clamp(0.0, 0.18);
    return Transform.translate(
      offset: Offset(0, _drag),
      child: Transform.scale(
        scale: shrink,
        child: GestureDetector(
          onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
          onDoubleTap: _toggleZoom,
          child: InteractiveViewer(
            transformationController: _transform,
            minScale: 1,
            maxScale: 4,
            // Unzoomed, a one-finger drag belongs to paging and closing.
            panEnabled: _zoomed,
            clipBehavior: Clip.none,
            onInteractionStart: _onStart,
            onInteractionUpdate: _onUpdate,
            onInteractionEnd: _onEnd,
            child: SizedBox.expand(
              child: Padding(
                // Clear of the title bar above and the gesture bar below.
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  insets.top + 76,
                  AppSpacing.md,
                  insets.bottom + AppSpacing.xxl,
                ),
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: _aspect ?? 3 / 4),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    builder: (context, shape, child) =>
                        AspectRatio(aspectRatio: shape, child: child),
                    child: Hero(
                      tag: widget.heroTag,
                      flightShuttleBuilder: _shuttle,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(_radius),
                        child: widget.photo.image(BoxFit.contain),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
