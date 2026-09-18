import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_gram/domain/models/plant.dart';
import 'package:plant_gram/enum.dart';
import 'package:plant_gram/stores/condition_update_store.dart';
import 'package:plant_gram/locator.dart';
import 'package:plant_gram/screens/auth/auth_landing_screen.dart';
import 'package:plant_gram/screens/auth/sign_in_screen.dart';
import 'package:plant_gram/screens/auth/sign_up_screen.dart';
import 'package:plant_gram/screens/auth/verify_code_screen.dart';
import 'package:plant_gram/screens/notifications/notifications_screen.dart';
import 'package:plant_gram/screens/onboarding/onboarding_screen.dart';
import 'package:plant_gram/screens/permissions/permissions_screen.dart';
import 'package:plant_gram/screens/plants/care_schedule_screen.dart';
import 'package:plant_gram/screens/plants/condition_confirmed_screen.dart';
import 'package:plant_gram/screens/plants/condition_update_screen.dart';
import 'package:plant_gram/screens/plants/plant_detail_screen.dart';
import 'package:plant_gram/screens/pokedex/pokedex_screen.dart';
import 'package:plant_gram/screens/pokedex/species_detail_screen.dart';
import 'package:plant_gram/screens/scanning/scan_result_screen.dart';
import 'package:plant_gram/screens/scanning/scan_screen.dart';
import 'package:plant_gram/screens/shell/app_shell.dart';
import 'package:plant_gram/screens/splash/splash_screen.dart';
import 'package:plant_gram/stores/app_shell_store.dart';
import 'package:plant_gram/stores/insights_store.dart';
import 'package:plant_gram/stores/notifications_store.dart';
import 'package:plant_gram/stores/plant_collection_store.dart';
import 'package:plant_gram/stores/pokedex_store.dart';
import 'package:plant_gram/stores/scanning_store.dart';

import 'package:plant_gram/interceptors/api_interceptor.dart';

import 'support/harness.dart';

/// Renders every designed screen so the implementation can be compared with
/// the specification. Goldens are rasterised with this machine's fonts, so
/// the comparisons only run on macOS; refresh them with
/// `flutter test --update-goldens` after a deliberate visual change.
void main() {
  if (!Platform.isMacOS) {
    return;
  }

  late Plant monstera;
  late Plant fiddle;
  late Plant paused;

  setUpAll(() async {
    await Harness.loadFonts();
  });

  setUp(() async {
    await Harness.bootstrap(prefs: {
      'pg.auth.token': 'mock-session',
      'pg.onboarding.complete': true,
      'pg.permissions.complete': true,
    });
    final collection = locator<PlantCollectionStore>();
    await collection.loadPlants(force: true);
    await locator<InsightsStore>().loadInsights(force: true);
    await locator<NotificationsStore>().loadNotifications(force: true);
    await locator<PokedexStore>().loadPokedex(force: true);
    monstera = collection.plantById('p-monstera')!;
    fiddle = collection.plantById('p-fiddle-leaf')!;
    paused = collection.plantById('p-parlour-palm')!;
  });

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget screen, {
    double scrollBy = 0,
    int frames = 18,
  }) async {
    await Harness.sizeTo(tester);
    await tester.pumpWidget(Harness.app(home: screen));
    await Harness.settle(tester, frames: frames);
    if (scrollBy > 0) {
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, Offset(0, -scrollBy),
            warnIfMissed: false);
        await Harness.settle(tester, frames: 8);
      }
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('01 splash', (t) async {
    await shoot(t, '01_splash', const SplashScreen(), frames: 10);
  });

  testWidgets('02 auth landing', (t) async {
    await shoot(t, '02_auth_landing', const AuthLandingScreen());
  });

  testWidgets('03 sign in', (t) async {
    await shoot(t, '03_sign_in', const SignInScreen());
  });

  testWidgets('04 sign up', (t) async {
    await shoot(t, '04_sign_up', const SignUpScreen());
  });

  testWidgets('05 verify code', (t) async {
    await shoot(t, '05_verify_code', const VerifyCodeScreen());
  });

  for (var step = 0; step < 5; step++) {
    testWidgets('06 onboarding step ${step + 1}', (t) async {
      await Harness.sizeTo(t);
      await t.pumpWidget(Harness.app(home: const OnboardingScreen()));
      await Harness.settle(t, frames: 10);
      for (var i = 0; i < step; i++) {
        await t.drag(find.byType(PageView), const Offset(-390, 0));
        await Harness.settle(t, frames: 10);
      }
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/06_onboarding_${step + 1}.png'),
      );
    });
  }

  testWidgets('07 permissions', (t) async {
    await shoot(t, '07_permissions', const PermissionsScreen());
  });

  testWidgets('08 home', (t) async {
    await shoot(t, '08_home', const AppShell());
  });

  testWidgets('09 home scrolled', (t) async {
    await shoot(t, '09_home_scrolled', const AppShell(), scrollBy: 700);
  });

  testWidgets('10 my plants', (t) async {
    locator<AppShellStore>().select(1);
    await shoot(t, '10_my_plants', const AppShell());
  });

  testWidgets('11 my plants scrolled', (t) async {
    locator<AppShellStore>().select(1);
    await shoot(t, '11_my_plants_scrolled', const AppShell(), scrollBy: 620);
  });

  testWidgets('12 my plants empty', (t) async {
    // Empty the collection through the real removal path so the repository
    // stays in step and the shell's reload cannot reseed it.
    final collection = locator<PlantCollectionStore>();
    for (final plant in [...collection.plants]) {
      await collection.removePlant(plant.id);
    }
    locator<AppShellStore>().select(1);
    await shoot(t, '12_my_plants_empty', const AppShell());
  });

  testWidgets('13 pokedex', (t) async {
    await shoot(t, '13_pokedex', const PokedexScreen(embedded: true));
  });

  testWidgets('14 pokedex grid', (t) async {
    await shoot(t, '14_pokedex_grid', const PokedexScreen(embedded: true),
        scrollBy: 700);
  });

  testWidgets('15 species detail', (t) async {
    await shoot(t, '15_species_detail',
        SpeciesDetailScreen(species: monstera.species));
  });

  testWidgets('16 species detail scrolled', (t) async {
    await shoot(t, '16_species_detail_scrolled',
        SpeciesDetailScreen(species: monstera.species),
        scrollBy: 820);
  });

  testWidgets('17 scan', (t) async {
    await shoot(t, '17_scan', const ScanScreen());
  });

  testWidgets('18 scan result', (t) async {
    await locator<ScanningStore>().scanPlant();
    await shoot(t, '18_scan_result', const ScanResultScreen());
  });

  testWidgets('19 scan result scrolled', (t) async {
    await locator<ScanningStore>().scanPlant();
    await shoot(t, '19_scan_result_scrolled', const ScanResultScreen(),
        scrollBy: 560);
  });

  testWidgets('20 plant dashboard', (t) async {
    await shoot(t, '20_plant_dashboard', PlantDetailScreen(plant: monstera));
  });

  testWidgets('21 plant dashboard mid', (t) async {
    await shoot(t, '21_plant_dashboard_mid', PlantDetailScreen(plant: monstera),
        scrollBy: 620);
  });

  testWidgets('22 plant dashboard lower', (t) async {
    await shoot(
        t, '22_plant_dashboard_lower', PlantDetailScreen(plant: monstera),
        scrollBy: 1300);
  });

  testWidgets('23 plant needs attention', (t) async {
    await shoot(t, '23_plant_attention', PlantDetailScreen(plant: fiddle));
  });

  testWidgets('24 plant paused', (t) async {
    await shoot(t, '24_plant_paused', PlantDetailScreen(plant: paused));
  });

  testWidgets('25 care schedule', (t) async {
    await shoot(t, '25_care_schedule', CareScheduleScreen(plant: monstera));
  });

  testWidgets('26 care schedule scrolled', (t) async {
    await shoot(t, '26_care_schedule_scrolled',
        CareScheduleScreen(plant: monstera),
        scrollBy: 720);
  });

  testWidgets('27 condition capture', (t) async {
    await shoot(t, '27_condition_capture',
        ConditionUpdateScreen(plant: monstera));
  });

  testWidgets('28 condition review', (t) async {
    await Harness.sizeTo(t);
    await t.pumpWidget(
        Harness.app(home: ConditionUpdateScreen(plant: monstera)));
    await Harness.settle(t, frames: 10);
    await t.tap(find.bySemanticsLabel('Take photo'));
    await Harness.settle(t, frames: 14);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/28_condition_review.png'));
  });

  testWidgets('29 condition details', (t) async {
    await Harness.sizeTo(t);
    await t.pumpWidget(
        Harness.app(home: ConditionUpdateScreen(plant: monstera)));
    await Harness.settle(t, frames: 10);
    await t.tap(find.bySemanticsLabel('Take photo'));
    await Harness.settle(t, frames: 14);
    await t.tap(find.text('Continue'));
    await Harness.settle(t, frames: 12);
    await t.tap(find.text(ConditionVerdict.concerns.title));
    await t.tap(find.text('Yellowing leaves'));
    await t.tap(find.text('Dry soil'));
    await Harness.settle(t, frames: 10);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/29_condition_details.png'));
  });

  testWidgets('30 condition confirmed', (t) async {
    final store = locator<ConditionUpdateStore>()..start(monstera);
    store.setVerdict(ConditionVerdict.healthy);
    await store.save();
    await shoot(
        t, '30_condition_confirmed', ConditionConfirmedScreen(store: store));
  });

  testWidgets('31 insights', (t) async {
    locator<AppShellStore>().select(3);
    await shoot(t, '31_insights', const AppShell());
  });

  testWidgets('32 insights scrolled', (t) async {
    locator<AppShellStore>().select(3);
    await shoot(t, '32_insights_scrolled', const AppShell(), scrollBy: 760);
  });

  testWidgets('33 notifications', (t) async {
    await shoot(t, '33_notifications', const NotificationsScreen());
  });

  testWidgets('34 profile', (t) async {
    locator<AppShellStore>().select(4);
    await shoot(t, '34_profile', const AppShell());
  });

  testWidgets('35 profile scrolled', (t) async {
    locator<AppShellStore>().select(4);
    await shoot(t, '35_profile_scrolled', const AppShell(), scrollBy: 640);
  });

  testWidgets('36 my plants loading', (t) async {
    // Hold every response so the skeletons stay up for the capture.
    await Harness.bootstrap(
      prefs: {'pg.auth.token': 'mock-session'},
      interceptors: const [
        LatencyInterceptor(duration: Duration(seconds: 30)),
      ],
    );
    locator<AppShellStore>().select(1);
    await Harness.sizeTo(t);
    await t.pumpWidget(Harness.app(home: const AppShell()));
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 90));
    }
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/36_my_plants_loading.png'));
    // Let the held responses land (loads chain a second call) so no timers
    // stay pending at teardown.
    await t.pump(const Duration(seconds: 31));
    await t.pump(const Duration(seconds: 31));
    await t.pump();
  });

  testWidgets('37 scan no match', (t) async {
    locator<ScanningStore>().simulateNoMatch(true);
    await Harness.sizeTo(t);
    await t.pumpWidget(Harness.app(home: const ScanScreen()));
    await Harness.settle(t, frames: 10);
    await t.tap(find.bySemanticsLabel('Identify'));
    await Harness.settle(t, frames: 20);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/37_scan_no_match.png'));
  });

  testWidgets('39 name a new plant', (t) async {
    await Harness.sizeTo(t);
    await t.pumpWidget(
        Harness.app(home: SpeciesDetailScreen(species: monstera.species)));
    await Harness.settle(t, frames: 12);
    await t.tap(find.text('Add to My Plants'));
    await Harness.settle(t, frames: 14);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/39_name_new_plant.png'));
  });

  testWidgets('38 remove plant sheet', (t) async {
    await Harness.sizeTo(t);
    await t.pumpWidget(Harness.app(home: PlantDetailScreen(plant: fiddle)));
    await Harness.settle(t, frames: 12);
    await t.tap(find.bySemanticsLabel('Plant options'));
    await Harness.settle(t, frames: 12);
    await t.tap(find.text('Remove from collection'));
    await Harness.settle(t, frames: 14);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/38_remove_plant.png'));
  });
}
