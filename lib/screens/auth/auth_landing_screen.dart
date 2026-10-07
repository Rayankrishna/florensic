import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../locator.dart';
import '../../routes.dart';
import '../../shared/components/app_button.dart';
import '../../stores/auth_store.dart';
import '../../theme.dart';
import '../splash/splash_screen.dart';

/// `Your plants, in one place.` — the entry point for a signed-out keeper.
class AuthLandingScreen extends StatelessWidget {
  const AuthLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = locator<AuthStore>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.lightOverlay,
      child: Scaffold(
        // The hero runs to the very top edge — including behind the status
        // bar — so there is no seam between the header and the body.
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.sizeOf(context).height * 0.58,
              child: const _CanopyHero(),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.xl,
                      AppSpacing.gutter,
                      0,
                    ),
                    child: Row(
                      children: [
                        const AppMark(size: 40),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          'Florensic',
                          style: AppText.heading20.copyWith(fontSize: 17.5),
                        ),
                      ],
                    ),
                  ),
                  // Everything else is pinned low, which leaves the tree the top
                  // half of the screen to itself.
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.gutter,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Your plants,\nin one place.',
                          style: AppText.display40.copyWith(fontSize: 35.5),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Discover, care for, and understand your plants.',
                          style: AppText.body15.copyWith(fontSize: 15),
                        ),
                        const SizedBox(height: AppSpacing.xxl + AppSpacing.xs),
                        Observer(
                          builder: (context) => Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppButton.primary(
                                label: 'Continue with email',
                                loading: store.isLoading,
                                onPressed: () => Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.signIn),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'New here?',
                              style: AppText.body15.copyWith(fontSize: 14),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            AppButton(
                              label: 'Create an account',
                              style: AppButtonStyle.link,
                              expand: false,
                              onPressed: () => Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.signUp),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.lg,
                          ),
                          child: Text.rich(
                            TextSpan(
                              style: AppText.body13.copyWith(fontSize: 12),
                              children: const [
                                TextSpan(
                                  text: 'By continuing you agree to our ',
                                ),
                                TextSpan(
                                  text: 'Terms',
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: AppColors.ink,
                                  ),
                                ),
                                TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: AppColors.ink,
                                  ),
                                ),
                                TextSpan(text: '.'),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
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
    );
  }
}

class _CanopyHero extends StatelessWidget {
  const _CanopyHero();

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
              colors: [Color(0xFFE4F4C8), Color(0xFFEAF5DE), AppColors.ground],
              stops: [0, 0.55, 0.92],
            ),
          ),
        ),
        // A whole tree, trunk and all. The canopy cut-out reads as a fragment
        // once it is scaled up, because it has no crown and no base.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.xxxl,
            AppSpacing.gutter,
            0,
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.scale(
                scale: 1.04 - t * 0.04,
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            ),
            child: Image.asset(
              'assets/images/tree_pine.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
            ),
          ),
        ),
        // Settle the trunk into the ground rather than ending it on a line.
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 96,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00F1F7F6), AppColors.ground],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
