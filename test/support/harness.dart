import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_gram/interceptors/api_interceptor.dart';
import 'package:plant_gram/utils/app_clock.dart';
import 'package:plant_gram/locator.dart';
import 'package:plant_gram/routes.dart';
import 'package:plant_gram/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared setup for widget tests: the real fonts, a seeded store graph and a
/// zero-latency API client so loading states settle.
class Harness {
  const Harness._();

  static const Size phone = Size(390, 844);

  static Future<void> bootstrap({
    Map<String, Object> prefs = const {},
    List<ApiInterceptor> interceptors = const [],
  }) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Pin the clock so schedules, calendars and timestamps render the same on
    // every run. Thursday 17 September 2026, mid-morning — the moment the
    // specification's screens depict.
    AppClock.now = () => DateTime(2026, 9, 17, 9, 14);
    SharedPreferences.setMockInitialValues(prefs);
    await locator.reset();
    await setupLocator(interceptors: interceptors);
  }

  /// Loads the bundled Outfit and Plus Jakarta Sans faces so rendered text
  /// matches the running app rather than the test fallback font.
  static Future<void> loadFonts() async {
    for (final family in ['Outfit', 'PlusJakartaSans']) {
      final loader = FontLoader(family);
      for (final weight in [400, 500, 600, 700, 800]) {
        final file = File('assets/fonts/$family-$weight.ttf');
        if (!file.existsSync()) continue;
        loader.addFont(
          file.readAsBytes().then((b) => ByteData.view(b.buffer)),
        );
      }
      await loader.load();
    }
  }

  static Widget app({String? initialRoute, Widget? home}) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      initialRoute: home == null ? (initialRoute ?? AppRoutes.splash) : null,
      onGenerateRoute: home == null ? AppRoutes.onGenerateRoute : null,
      home: home,
    );
  }

  /// Pumps frames without waiting for repeating animations to finish, then
  /// decodes any asset images (which needs real async work).
  static Future<void> settle(WidgetTester tester,
      {int frames = 18, Duration step = const Duration(milliseconds: 90)}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(step);
    }
    await precacheImages(tester);
    for (var i = 0; i < 4; i++) {
      await tester.pump(step);
    }
  }

  static Future<void> precacheImages(WidgetTester tester) async {
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        final image = element.widget as Image;
        await precacheImage(image.image, element);
      }
    });
  }

  static Future<void> sizeTo(WidgetTester tester, [Size size = phone]) async {
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
  }
}
