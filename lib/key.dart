/// Storage keys and widget keys used across the app.
///
/// Keeping them in one place stops string literals leaking into widgets and
/// makes the persisted contract easy to audit.
library;

class StorageKeys {
  const StorageKeys._();

  static const String onboardingComplete = 'pg.onboarding.complete';
  static const String permissionsComplete = 'pg.permissions.complete';
  static const String grantedPermissions = 'pg.permissions.granted';
  static const String authToken = 'pg.auth.token';
  static const String userName = 'pg.user.name';
  static const String userEmail = 'pg.user.email';
  static const String keepSignedIn = 'pg.auth.keepSignedIn';
  static const String lastTab = 'pg.shell.lastTab';
}

class AppKeys {
  const AppKeys._();

  static const String plantHeroPrefix = 'plant-hero-';
  static const String speciesHeroPrefix = 'species-hero-';

  static String plantHero(String id) => '$plantHeroPrefix$id';
  static String speciesHero(String id) => '$speciesHeroPrefix$id';
}
