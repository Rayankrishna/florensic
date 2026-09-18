import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../locator.dart';
import '../../routes.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_surfaces.dart';
import '../../shared/widgets/health_ring.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../stores/condition_update_store.dart';
import '../../stores/plant_collection_store.dart';
import '../../theme.dart';
import '../../utils/date_format.dart';
import '../../utils/app_clock.dart';

/// `Condition updated` — the confirmation after a check-in is saved.
class ConditionConfirmedScreen extends StatelessWidget {
  const ConditionConfirmedScreen({super.key, required this.store});

  final ConditionUpdateStore store;

  @override
  Widget build(BuildContext context) {
    final score = store.newScore ?? 0;
    final delta = store.scoreDelta;
    final plant = store.plant;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.lightOverlay,
      child: Scaffold(
        body: ScreenBackground(
          glowAlignment: const Alignment(0, -0.55),
          glowColor: const Color(0xFFD2E7B8),
          glowRadius: 0.8,
          glowOpacity: 0.85,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  HealthRing(
                    score: 82,
                    size: 190,
                    strokeWidth: 15,
                    duration: const Duration(milliseconds: 900),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 520),
                      curve: Curves.easeOutBack,
                      builder: (context, t, child) =>
                          Transform.scale(scale: t, child: child),
                      child: Container(
                        width: 108,
                        height: 108,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.ink,
                          shape: BoxShape.circle,
                        ),
                        child: const PgIcon(PgIcons.check,
                            size: 46, color: AppColors.leaf),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  Text('Condition updated',
                      style: AppText.display40.copyWith(fontSize: 33.5)),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Your plant health history has been refreshed.',
                    textAlign: TextAlign.center,
                    style: AppText.body15.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.cardPadding),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Plant health',
                                        style: AppText.body15
                                            .copyWith(fontSize: 15)),
                                    const SizedBox(height: AppSpacing.sm),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        AnimatedScore(
                                          value: score,
                                          style: AppText.metric
                                              .copyWith(fontSize: 35.5),
                                        ),
                                        const SizedBox(width: 6),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 6),
                                          child: Text(
                                            delta >= 0 ? '+$delta' : '$delta',
                                            style: AppText.heading17.copyWith(
                                              fontSize: 16,
                                              color: delta >= 0
                                                  ? AppColors.healthyDeep
                                                  : AppColors.criticalDeep,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg, vertical: 10),
                                decoration: const BoxDecoration(
                                  color: AppColors.leaf,
                                  borderRadius: AppRadius.pillR,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 9,
                                      height: 9,
                                      decoration: const BoxDecoration(
                                        color: AppColors.ink,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text('ACTIVE CARE',
                                        style: AppText.caption12.copyWith(
                                          fontSize: 11.5,
                                          color: AppColors.ink,
                                          letterSpacing: 1.1,
                                        )),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(
                            height: 1,
                            color: AppColors.line,
                            indent: AppSpacing.cardPadding,
                            endIndent: AppSpacing.cardPadding),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.cardPadding),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.neutralTint,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.tile),
                                ),
                                child: const PgIcon(PgIcons.calendar,
                                    size: 24, color: AppColors.inkMuted),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Next check-in · '
                                      '${AppDate.shortDate(store.nextCheckIn ?? AppClock.now())}',
                                      style: AppText.heading17
                                          .copyWith(fontSize: 16.5),
                                    ),
                                    const SizedBox(height: 2),
                                    Text('Window stays open for three days',
                                        style: AppText.body13
                                            .copyWith(fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                  AppButton.primary(
                    label: 'View plant dashboard',
                    onPressed: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      if (plant != null) {
                        navigator.pushNamed(AppRoutes.plantDetail,
                            arguments: locator<PlantCollectionStore>()
                                    .plantById(plant.id) ??
                                plant);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Back to home',
                    style: AppButtonStyle.link,
                    onPressed: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
