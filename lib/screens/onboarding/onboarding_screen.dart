import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../locator.dart';
import '../../routes.dart';
import '../../shared/components/app_button.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../stores/onboarding_store.dart';
import '../../theme.dart';
import 'onboarding_heroes.dart';

/// The five-step introduction. Each step pairs a bespoke hero with the same
/// copy block and footer, so only the artwork changes as you advance.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final OnboardingStore _store = locator<OnboardingStore>();
  final PageController _pager = PageController();

  static const List<({String title, String body})> _steps = [
    (
      title: 'Meet your plants',
      body: 'Build a collection that remembers every plant you own — species, '
          'room, and the day it arrived.',
    ),
    (
      title: 'Know what they\nneed',
      body: 'Watering rhythm, light, and the weather outside your window — read '
          'together, so advice fits today rather than a generic schedule.',
    ),
    (
      title: 'Track their health',
      body: 'Send a photo every couple of weeks. Each one becomes part of a '
          'health record you can look back through.',
    ),
    (
      title: 'Stay ahead of\nproblems',
      body: 'Reminders arrive before trouble does, and shift with the weather '
          'instead of a fixed calendar.',
    ),
    (
      title: 'Let\'s grow your\ncollection',
      body: "Scan the plant nearest to you and it's in — profile, schedule and "
          'health record included.',
    ),
  ];

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _next() {
    if (_store.isLastStep) {
      _finish();
      return;
    }
    _pager.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    await _store.completeOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.permissions);
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final dark = _store.currentStep == 2;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: dark ? AppTheme.darkOverlay : AppTheme.lightOverlay,
          child: Scaffold(
            backgroundColor: AppColors.ground,
            body: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pager,
                    itemCount: _steps.length,
                    onPageChanged: _store.goTo,
                    itemBuilder: (context, index) => _OnboardingPage(
                      index: index,
                      title: _steps[index].title,
                      body: _steps[index].body,
                      onSkip: _finish,
                      store: _store,
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                        AppSpacing.lg, AppSpacing.gutter, AppSpacing.lg),
                    child: _store.isLastStep
                        ? Column(
                            children: [
                              AppButton.primary(
                                  label: 'Get started', onPressed: _finish),
                              const SizedBox(height: AppSpacing.md),
                              AppButton(
                                label: "I'll add plants later",
                                style: AppButtonStyle.link,
                                onPressed: _finish,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  label: 'Continue',
                                  style: _store.currentStep == 3
                                      ? AppButtonStyle.dark
                                      : AppButtonStyle.primary,
                                  onPressed: _next,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              CircleIconButton(
                                icon: PgIcons.chevronRight,
                                onPressed: _next,
                                size: 58,
                                background: _store.currentStep == 3
                                    ? AppColors.leaf
                                    : AppColors.ink,
                                foreground: _store.currentStep == 3
                                    ? AppColors.ink
                                    : AppColors.leaf,
                                semanticLabel: 'Next step',
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.index,
    required this.title,
    required this.body,
    required this.onSkip,
    required this.store,
  });

  final int index;
  final String title;
  final String body;
  final VoidCallback onSkip;
  final OnboardingStore store;

  @override
  Widget build(BuildContext context) {
    final dark = index == 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 55,
          child: Stack(
            fit: StackFit.expand,
            children: [
              OnboardingHero(step: index),
              SafeArea(
                bottom: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, 0),
                  child: Row(
                    children: [
                      Observer(
                        builder: (context) => _StepDots(
                          current: store.currentStep,
                          total: kOnboardingStepCount,
                          onDark: dark,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onSkip,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md, horizontal: AppSpacing.sm),
                          child: Text(
                            index == 4 ? 'ALMOST THERE' : 'Skip',
                            style: index == 4
                                ? AppText.caption12.copyWith(
                                    fontSize: 12, letterSpacing: 1.8)
                                : AppText.heading17.copyWith(
                                    fontSize: 16.5,
                                    color: dark
                                        ? Colors.white
                                        : AppColors.inkMuted,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 45,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter, AppSpacing.xxxl, AppSpacing.gutter, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STEP ${index + 1} OF $kOnboardingStepCount',
                    style: AppText.caption12
                        .copyWith(fontSize: 12, letterSpacing: 2.2)),
                const SizedBox(height: AppSpacing.lg),
                Text(title, style: AppText.display40.copyWith(fontSize: 35.5)),
                const SizedBox(height: AppSpacing.lg),
                Text(body, style: AppText.body15.copyWith(fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({
    required this.current,
    required this.total,
    required this.onDark,
  });

  final int current;
  final int total;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 7),
          AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            width: i == current ? 30 : 11,
            height: 6,
            decoration: BoxDecoration(
              color: i == current
                  ? (onDark ? AppColors.leaf : AppColors.ink)
                  : (onDark
                      ? Colors.white.withValues(alpha: 0.35)
                      : AppColors.inkFaint.withValues(alpha: 0.45)),
              borderRadius: AppRadius.pillR,
            ),
          ),
        ],
      ],
    );
  }
}
