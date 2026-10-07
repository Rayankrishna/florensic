import 'package:flutter/widgets.dart';

/// How large the interface sits on screen.
///
/// Below 1.0 the whole app — spacing, icons, radii and type alike — is drawn a
/// little smaller, which is not the same as shrinking the type alone.
const double kUiScale = 0.94;

/// Lays the app out on a slightly larger canvas, then scales that canvas down
/// to the real screen.
///
/// Doing it in one place keeps every design token honest: `AppSpacing.gutter`
/// is still 20, the gutter simply lands on fewer physical pixels. Insets are
/// divided by the same factor so a notch or home indicator still reserves the
/// space it physically occupies.
class UiScale extends StatelessWidget {
  const UiScale({super.key, required this.child, this.scale = kUiScale});

  final Widget child;
  final double scale;

  @override
  Widget build(BuildContext context) {
    if (scale == 1) return child;
    final media = MediaQuery.of(context);
    final canvas = media.size / scale;
    final factor = 1 / scale;

    return MediaQuery(
      data: media.copyWith(
        size: canvas,
        padding: media.padding * factor,
        viewPadding: media.viewPadding * factor,
        viewInsets: media.viewInsets * factor,
        systemGestureInsets: media.systemGestureInsets * factor,
      ),
      // The OverflowBox sits outside the Transform so the canvas can be
      // laid out at its true, larger size. The other way round the Transform
      // reports the screen's size, and every tap below the fold misses.
      child: OverflowBox(
        alignment: Alignment.topLeft,
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: canvas.width,
            height: canvas.height,
            child: child,
          ),
        ),
      ),
    );
  }
}
