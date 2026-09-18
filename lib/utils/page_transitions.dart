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
