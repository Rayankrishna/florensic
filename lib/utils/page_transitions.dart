import 'package:flutter/material.dart';

/// Route builders shared by [AppRoutes].
///
/// The design never cuts between screens: pushes glide up and fade, modal
/// surfaces rise from the bottom edge, and confirmations bloom in place.
class AppTransitions {
  const AppTransitions._();

  static const Duration _fast = Duration(milliseconds: 320);
  static const Duration _modal = Duration(milliseconds: 420);

  /// Forward navigation: a short rise with a fade.
  static Route<T> glide<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: _fast,
      reverseTransitionDuration: _fast,
      pageBuilder: (context, animation, secondary) => page,
      transitionsBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final outgoing = CurvedAnimation(
          parent: secondary,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.035),
              end: Offset.zero,
            ).animate(curved),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(0, -0.02),
              ).animate(outgoing),
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Camera, scan and full-screen flows rise from the bottom.
  static Route<T> rise<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      fullscreenDialog: true,
      transitionDuration: _modal,
      reverseTransitionDuration: _fast,
      pageBuilder: (context, animation, secondary) => page,
      transitionsBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  /// Confirmations replace the flow rather than stacking on it.
  static Route<T> bloom<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: _modal,
      reverseTransitionDuration: _fast,
      pageBuilder: (context, animation, secondary) => page,
      transitionsBuilder: (context, animation, secondary, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// A photo opened full screen. The picture itself flies out of the spot it
  /// was tapped — the same hero flight a plant card makes into its page —
  /// so the route only fades the ground in behind it. Not opaque: the page
  /// underneath stays drawn while the flight runs and while a drag down
  /// lets it show through.
  static Route<T> photo<T>(Widget page, RouteSettings settings) {
    return _SeeThroughRoute<T>(
      settings: settings,
      transitionDuration: _fast,
      reverseTransitionDuration: _fast,
      pageBuilder: (context, animation, secondary) => page,
      transitionsBuilder: (context, animation, secondary, child) =>
          FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
        child: child,
      ),
    );
  }

  /// Cross-fade, for root swaps such as splash → auth → shell.
  static Route<T> fade<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 440),
      pageBuilder: (context, animation, secondary) => page,
      transitionsBuilder: (context, animation, secondary, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
  }
}

/// A route the page beneath keeps showing through. It never drives that
/// page's outgoing transition, so the page stays exactly where it was —
/// a drag down reveals it in place, and a photo flies back into a spot that
/// is not sliding away. Heroes still fly: it is a page route.
class _SeeThroughRoute<T> extends PageRouteBuilder<T> {
  _SeeThroughRoute({
    super.settings,
    required super.pageBuilder,
    required super.transitionsBuilder,
    super.transitionDuration,
    super.reverseTransitionDuration,
  }) : super(opaque: false);

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) => false;
}
