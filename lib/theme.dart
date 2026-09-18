import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The Florensic design system.
///
/// Every token here comes from the design specification (Foundations page):
/// colour, typography, spacing, radius and elevation. Widgets must read from
/// these rather than hard-coding values.
class AppColors {
  const AppColors._();

  // ── Core palette ─────────────────────────────────────────────────────────
  /// The accent. A calm leaf green rather than the specification's neon lime.
  static const Color leaf = Color(0xFF7CB342);

  /// Dark surfaces and headline text. A visible grey — nothing in the app
  /// renders as pure black.
  static const Color ink = Color(0xFF383E3B);
  static const Color ground = Color(0xFFF1F7F6);
  static const Color softGreen = Color(0xFFDCEFD0);
  static const Color surface = Color(0xFFFFFFFF);

  /// Muted body copy — sampled from the specification's secondary text.
  static const Color inkMuted = Color(0xFF4F5654);
  static const Color inkFaint = Color(0xFF7A8380);

  /// Hairlines and inactive rails. Never combined with a shadow.
  static const Color line = Color(0xFFE2EBE8);
  static const Color track = Color(0xFFE6EDEA);

  // ── Signal fills (carry ink text only) ───────────────────────────────────
  static const Color water = Color(0xFF7FB7E8);
  static const Color caution = Color(0xFFF1B33C);
  static const Color critical = Color(0xFFE8836F);

  /// Deep pairs, for signal-coloured text on white.
  static const Color waterDeep = Color(0xFF1F5F92);
  static const Color cautionDeep = Color(0xFF8A5A00);
  static const Color criticalDeep = Color(0xFFA33D28);

  /// Tints, for icon tiles and soft cards.
  static const Color waterTint = Color(0xFFDCECFC);
  static const Color cautionTint = Color(0xFFFEEECD);
  static const Color criticalTint = Color(0xFFFADFD8);
  static const Color greenTint = Color(0xFFD8EECF);
  static const Color leafSoft = Color(0xFFE4F1CE);
  static const Color neutralTint = Color(0xFFEDF2F0);

  static const Color healthyDeep = Color(0xFF1E5427);

  // ── Botanical grounds ────────────────────────────────────────────────────
  static const List<Color> mint = [Color(0xFFE9F7D8), Color(0xFFD2EAC4)];
  static const List<Color> sage = [Color(0xFFE4F2EC), Color(0xFFCFE3D6)];

  /// Hero / scan surfaces.
  static const Color scanDark = Color(0xFF0C1B10);
  static const Color scanMid = Color(0xFF1B3A22);
}

/// Radius scale: 12 chip · 20 tile · 28 card · full pill.
class AppRadius {
  const AppRadius._();

  static const double chip = 12;
  static const double tile = 20;
  static const double card = 28;
  static const double pill = 999;

  static const BorderRadius chipR = BorderRadius.all(Radius.circular(chip));
  static const BorderRadius tileR = BorderRadius.all(Radius.circular(tile));
  static const BorderRadius cardR = BorderRadius.all(Radius.circular(card));
  static const BorderRadius pillR = BorderRadius.all(Radius.circular(pill));
}

/// Spacing scale: 4 · 8 · 12 · 16 · 20 · 24 · 32.
/// Screen gutter 20. Section rhythm 28. Card padding 20–24.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  static const double gutter = 20;
  static const double section = 28;
  static const double cardPadding = 20;
  static const double cardPaddingLarge = 24;

  /// Touch targets never below 44.
  static const double minTouchTarget = 44;
}

/// Shadows are wide, low-opacity and green-tinted.
/// Never a hard drop shadow; never a border *and* a shadow on one surface.
class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> flat = <BoxShadow>[];

  static const List<BoxShadow> raised = [
    BoxShadow(
      color: Color(0x0F1E3B24),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x1A1E3B24),
      blurRadius: 40,
      offset: Offset(0, 16),
      spreadRadius: -8,
    ),
    BoxShadow(
      color: Color(0x0A1E3B24),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> navBar = [
    BoxShadow(
      color: Color(0x18222B24),
      blurRadius: 28,
      offset: Offset(0, 12),
      spreadRadius: -6,
    ),
  ];
}

/// Type scale. Display / Title / Heading / Metric use Outfit;
/// Body / Caption use Plus Jakarta Sans.
class AppText {
  const AppText._();

  static const String display = 'Outfit';
  static const String body = 'PlusJakartaSans';

  static const TextStyle display40 = TextStyle(
    fontFamily: display,
    fontSize: 37,
    height: 1.05,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
    color: AppColors.ink,
  );

  static const TextStyle title28 = TextStyle(
    fontFamily: display,
    fontSize: 26,
    height: 1.12,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.7,
    color: AppColors.ink,
  );

  static const TextStyle heading20 = TextStyle(
    fontFamily: display,
    fontSize: 18.5,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.ink,
  );

  static const TextStyle heading17 = TextStyle(
    fontFamily: display,
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.ink,
  );

  static const TextStyle body15 = TextStyle(
    fontFamily: body,
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AppColors.inkMuted,
  );

  static const TextStyle body15Ink = TextStyle(
    fontFamily: body,
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
  );

  static const TextStyle body13 = TextStyle(
    fontFamily: body,
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: AppColors.inkMuted,
  );

  static const TextStyle caption12 = TextStyle(
    fontFamily: body,
    fontSize: 11.5,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.1,
    color: AppColors.inkMuted,
  );

  static const TextStyle label13 = TextStyle(
    fontFamily: body,
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  static const TextStyle metric = TextStyle(
    fontFamily: display,
    fontSize: 41,
    height: 1.0,
    fontWeight: FontWeight.w800,
    letterSpacing: -2,
    color: AppColors.ink,
  );

  static const TextStyle button = TextStyle(
    fontFamily: display,
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    color: AppColors.ink,
  );
}

class AppTheme {
  const AppTheme._();

  static const SystemUiOverlayStyle lightOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.ground,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static const SystemUiOverlayStyle darkOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.scanDark,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static ThemeData build() {
    const scheme = ColorScheme.light(
      primary: AppColors.leaf,
      onPrimary: AppColors.ink,
      secondary: AppColors.ink,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.criticalDeep,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.ground,
      fontFamily: AppText.body,
      splashFactory: InkRipple.splashFactory,
      highlightColor: Colors.transparent,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.ink,
        selectionColor: AppColors.leafSoft,
        selectionHandleColor: AppColors.ink,
      ),
      textTheme: const TextTheme(
        displayLarge: AppText.display40,
        headlineMedium: AppText.title28,
        titleLarge: AppText.heading20,
        titleMedium: AppText.heading17,
        bodyLarge: AppText.body15Ink,
        bodyMedium: AppText.body15,
        bodySmall: AppText.body13,
        labelSmall: AppText.caption12,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
