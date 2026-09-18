import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../locator.dart';
import '../../routes.dart';
import '../../shared/components/app_button.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../stores/auth_store.dart';
import '../../theme.dart';
import '../splash/splash_screen.dart';

/// `Your plants, in one place.` — the entry point for a signed-out keeper.
class AuthLandingScreen extends StatelessWidget {
  const AuthLandingScreen({super.key});

  Future<void> _continueWith(BuildContext context, String provider) async {
    final store = locator<AuthStore>();
    final ok = await store.continueWithProvider(provider);
    if (ok && context.mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = locator<AuthStore>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.lightOverlay,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter, AppSpacing.xl, AppSpacing.gutter, 0),
                child: Row(
                  children: [
                    const AppMark(size: 40),
                    const SizedBox(width: AppSpacing.md),
                    Text('Florensic',
                        style: AppText.heading20.copyWith(fontSize: 17.5)),
                  ],
                ),
              ),
              // The canopy owns the top third and fades into the ground so the
              // headline always sits on a clear surface.
              const Expanded(flex: 34, child: _CanopyHero()),
              Expanded(
                flex: 66,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      Text('Your plants,\nin one place.',
                          style: AppText.display40.copyWith(fontSize: 35.5)),
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
                            AppButton.dark(
                              label: 'Continue with Apple',
                              icon: PgIcons.apple,
                              loading: store.isLoading,
                              onPressed: () => _continueWith(context, 'apple'),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppButton.outline(
                              label: 'Continue with Google',
                              icon: PgIcons.google,
                              onPressed: () => _continueWith(context, 'google'),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppButton.primary(
                              label: 'Continue with email',
                              onPressed: () => Navigator.of(context)
                                  .pushNamed(AppRoutes.signIn),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('New here?',
                              style: AppText.body15.copyWith(fontSize: 14)),
                          const SizedBox(width: AppSpacing.sm),
                          AppButton(
                            label: 'Create an account',
                            style: AppButtonStyle.link,
                            expand: false,
                            onPressed: () => Navigator.of(context)
                                .pushNamed(AppRoutes.signUp),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
                        child: Text.rich(
                          TextSpan(
                            style: AppText.body13.copyWith(fontSize: 12),
                            children: const [
                              TextSpan(text: 'By continuing you agree to our '),
                              TextSpan(
                                text: 'Terms',
                                style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: AppColors.ink),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: AppColors.ink),
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
              ),
            ],
          ),
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
              colors: [Color(0xFFE4F4C8), Color(0xFFEBF6E2), AppColors.ground],
              stops: [0, 0.6, 1],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.scale(
                scale: 1.06 - t * 0.06,
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            ),
            child: Image.asset(
              'assets/images/tree_canopy.png',
              fit: BoxFit.cover,
              width: double.infinity,
              alignment: Alignment.bottomCenter,
            ),
          ),
        ),
        // Feather the photograph into the ground.
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
