import 'package:flutter/material.dart';

import 'domain/models/plant.dart';
import 'domain/models/plant_species.dart';
import 'screens/auth/auth_landing_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/verify_code_screen.dart';
import 'screens/insights/insights_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/permissions/permissions_screen.dart';
import 'screens/plants/care_schedule_screen.dart';
import 'screens/plants/condition_confirmed_screen.dart';
import 'screens/plants/condition_update_screen.dart';
import 'screens/plants/plant_detail_screen.dart';
import 'screens/pokedex/pokedex_screen.dart';
import 'screens/pokedex/species_detail_screen.dart';
import 'screens/scanning/scan_result_screen.dart';
import 'screens/scanning/scan_screen.dart';
import 'screens/shell/app_shell.dart';
import 'screens/splash/splash_screen.dart';
import 'stores/condition_update_store.dart';
import 'theme.dart';
import 'utils/page_transitions.dart';

/// Named routes and their transitions.
///
/// Arguments are passed as typed objects rather than maps so a wrong push is
/// a compile-time or immediately visible error rather than a silent null.
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String authLanding = '/auth';
  static const String signIn = '/auth/sign-in';
  static const String signUp = '/auth/sign-up';
  static const String verifyCode = '/auth/verify';
  static const String onboarding = '/onboarding';
  static const String permissions = '/permissions';
  static const String shell = '/home';
  static const String plantDetail = '/plant';
  static const String careSchedule = '/plant/schedule';
  static const String conditionUpdate = '/plant/condition';
  static const String conditionConfirmed = '/plant/condition/done';
  static const String pokedex = '/pokedex';
  static const String speciesDetail = '/pokedex/species';
  static const String scan = '/scan';
  static const String scanResult = '/scan/result';
  static const String notifications = '/notifications';
  static const String insights = '/insights';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case splash:
        return AppTransitions.fade(const SplashScreen(), settings);

      case authLanding:
        return AppTransitions.fade(const AuthLandingScreen(), settings);

      case signIn:
        return AppTransitions.glide(const SignInScreen(), settings);

      case signUp:
        return AppTransitions.glide(const SignUpScreen(), settings);

      case verifyCode:
        return AppTransitions.glide(const VerifyCodeScreen(), settings);

      case onboarding:
        return AppTransitions.fade(const OnboardingScreen(), settings);

      case permissions:
        return AppTransitions.glide(const PermissionsScreen(), settings);

      case shell:
        return AppTransitions.fade(const AppShell(), settings);

      case plantDetail:
        return AppTransitions.glide(
          PlantDetailScreen(plant: args! as Plant),
          settings,
        );

      case careSchedule:
        return AppTransitions.glide(
          CareScheduleScreen(plant: args! as Plant),
          settings,
        );

      case conditionUpdate:
        return AppTransitions.rise(
          ConditionUpdateScreen(plant: args! as Plant),
          settings,
        );

      case conditionConfirmed:
        return AppTransitions.bloom(
          ConditionConfirmedScreen(store: args! as ConditionUpdateStore),
          settings,
        );

      case pokedex:
        return AppTransitions.glide(
          const PokedexScreen(embedded: true),
          settings,
        );

      case speciesDetail:
        return AppTransitions.glide(
          SpeciesDetailScreen(species: args! as PlantSpecies),
          settings,
        );

      case scan:
        return AppTransitions.rise(const ScanScreen(), settings);

      case scanResult:
        return AppTransitions.glide(const ScanResultScreen(), settings);

      case notifications:
        return AppTransitions.glide(const NotificationsScreen(), settings);

      case insights:
        return AppTransitions.glide(
          const Scaffold(
            backgroundColor: AppColors.ground,
            body: InsightsScreen(),
          ),
          settings,
        );

      default:
        return AppTransitions.fade(const _UnknownRoute(), settings);
    }
  }
}

class _UnknownRoute extends StatelessWidget {
  const _UnknownRoute();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('That screen has moved',
                  style: AppText.title28.copyWith(fontSize: 22.5)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Head back and try again.',
                textAlign: TextAlign.center,
                style: AppText.body15.copyWith(fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
