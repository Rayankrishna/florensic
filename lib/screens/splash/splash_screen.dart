import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../locator.dart';
import '../../routes.dart';
import '../../shared/components/app_surfaces.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../stores/auth_store.dart';
import '../../stores/onboarding_store.dart';
import '../../stores/permissions_store.dart';
import '../../theme.dart';

/// The opening screen: the mark, the name, and a determinate loading rail
/// while the session and seed data are restored.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  late final Animation<double> _tree = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
  );

  late final Animation<double> _copy = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
  );

  Timer? _handoff;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = locator<AuthStore>();
    final onboarding = locator<OnboardingStore>()..restore();
    final permissions = locator<PermissionsStore>()..restore();
    await auth.restoreSession();
    if (!mounted) return;
    _handoff = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _goNext(auth, onboarding, permissions);
    });
  }

  void _goNext(
    AuthStore auth,
    OnboardingStore onboarding,
    PermissionsStore permissions,
  ) {
    final String next;
    if (!auth.isAuthenticated) {
      next = AppRoutes.authLanding;
    } else if (!onboarding.completed) {
      next = AppRoutes.onboarding;
    } else if (!permissions.completed) {
      next = AppRoutes.permissions;
    } else {
      next = AppRoutes.shell;
    }
    Navigator.of(context).pushReplacementNamed(next);
  }

  @override
  void dispose() {
    _handoff?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.lightOverlay,
      child: Scaffold(
        body: ScreenBackground(
          glowAlignment: const Alignment(0, -1),
          glowColor: const Color(0xFFD7E9C2),
          glowRadius: 1.1,
          glowOpacity: 0.75,
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: FadeTransition(
                    opacity: _tree,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 1.06, end: 1).animate(_tree),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.gutter),
                        child: Image.asset(
                          'assets/images/tree_pine.png',
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                ),
                FadeTransition(
                  opacity: _copy,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.14),
                      end: Offset.zero,
                    ).animate(_copy),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                          AppSpacing.xxxl, AppSpacing.gutter, AppSpacing.xxl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const AppMark(size: 44),
                              const SizedBox(width: AppSpacing.md),
                              Text('EST. 2026',
                                  style: AppText.caption12.copyWith(
                                      fontSize: 12, letterSpacing: 2.4)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          RichText(
                            text: TextSpan(
                              style: AppText.display40.copyWith(fontSize: 48.5),
                              children: const [
                                TextSpan(text: 'Florensic'),
                                TextSpan(
                                  text: '.',
                                  style: TextStyle(color: AppColors.leaf),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'A living index of every plant you keep — and how '
                            'each one is really doing.',
                            style: AppText.body15.copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: AppSpacing.xxxl),
                          _LoadingRail(animation: _controller),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The ink badge carrying the lime leaf — the app's mark.
class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 44, this.radius});

  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(radius ?? size * 0.32),
      ),
      child: PgIcon(PgIcons.leaf, size: size * 0.52, color: AppColors.leaf),
    );
  }
}

class _LoadingRail extends StatelessWidget {
  const _LoadingRail({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 5,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) => LinearProgressIndicator(
            value: Curves.easeInOut.transform(animation.value) * 0.72 + 0.04,
            backgroundColor: AppColors.track,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.leaf),
          ),
        ),
      ),
    );
  }
}
