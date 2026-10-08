/// Shared enumerations for Florensic.
library;

/// Health bands drive the ring colour: lime above 70, amber 40–69,
/// coral below 40 (Foundations · Health score).
///
/// A plant with no band — never scored, or paused — carries `null`; there is
/// no "paused" band.
enum HealthBand { thriving, watch, critical }

/// Where a plant sits in its care cycle, in order: one missed check-in
/// window makes it `stale`, a second pauses it.
enum CareStatus { active, stale, paused }

/// A row on today's care list. [unknown] is a kind this build does not know
/// yet — it still renders its own title and detail and can be completed.
enum CareTaskKind { watering, condition, treatmentStep, environment, unknown }

/// Status dot on a metric card.
enum MetricStatus { good, watch, bad, neutral }

/// Which metric a card describes.
enum MetricKind { watering, light, environment, condition }

/// Collection filter chips on My Plants.
enum PlantFilter { all, indoor, outdoor, needsAttention }

/// Discovery filter chips on the Pokedex.
enum PokedexFilter { indoor, lowLight, beginner, petFriendly }

/// Notification filter chips.
enum NotificationFilter { all, watering, checkIns, environment }

/// Notification category, which picks the icon and tint.
enum NotificationKind {
  conditionUpdate,
  watering,
  environment,
  healthChange,
  checkInMissed,
  appUpdate,
}

/// The three answers on the condition-details step.
enum ConditionVerdict { healthy, concerns, needsAttention }

/// Scan framing target.
enum ScanTarget { leaf, wholePlant, flower }

/// Identification lifecycle.
enum ScanStatus { idle, scanning, matched, noMatch, offline }

/// Trend chart range selector.
enum TrendRange { week, month, quarter }

/// Care-history event type. [other] covers a type this build does not know.
enum CareEventType {
  added,
  watered,
  wateringSkipped,
  conditionUpdate,
  checkInMissed,
  note,
  speciesCorrected,
  resumed,
  treatment,
  repotted,
  moved,
  other,
}

/// Runtime permissions asked for during setup, in the order they are shown.
/// Reminders are not here: nothing sends one yet, so there is nothing to ask
/// for.
enum PermissionKind { camera, photoLibrary, location }

/// What the OS says about one permission.
enum PermissionState {
  /// Not read yet.
  unknown,
  granted,

  /// Refused, or never asked — the system prompt can still be shown.
  denied,

  /// Refused for good — only Settings can change it.
  blocked,
}

/// Generic async lifecycle used by the stores.
enum LoadState { idle, loading, ready, empty, error }

extension HealthBandX on HealthBand {
  /// `thriving >= 70 · watch >= 40 · critical`; no score, no band.
  static HealthBand? fromScore(int? score) {
    if (score == null) return null;
    if (score >= 70) return HealthBand.thriving;
    if (score >= 40) return HealthBand.watch;
    return HealthBand.critical;
  }
}

extension PlantFilterX on PlantFilter {
  String get label => switch (this) {
        PlantFilter.all => 'All',
        PlantFilter.indoor => 'Indoor',
        PlantFilter.outdoor => 'Outdoor',
        PlantFilter.needsAttention => 'Needs attention',
      };
}

extension PokedexFilterX on PokedexFilter {
  String get label => switch (this) {
        PokedexFilter.indoor => 'Indoor',
        PokedexFilter.lowLight => 'Low light',
        PokedexFilter.beginner => 'Beginner',
        PokedexFilter.petFriendly => 'Pet friendly',
      };
}

extension NotificationFilterX on NotificationFilter {
  String get label => switch (this) {
        NotificationFilter.all => 'All',
        NotificationFilter.watering => 'Watering',
        NotificationFilter.checkIns => 'Check-ins',
        NotificationFilter.environment => 'Environment',
      };
}

extension TrendRangeX on TrendRange {
  String get label => switch (this) {
        TrendRange.week => '7D',
        TrendRange.month => '30D',
        TrendRange.quarter => '90D',
      };

  int get days => switch (this) {
        TrendRange.week => 7,
        TrendRange.month => 30,
        TrendRange.quarter => 90,
      };
}

extension ScanTargetX on ScanTarget {
  String get label => switch (this) {
        ScanTarget.leaf => 'Leaf',
        ScanTarget.wholePlant => 'Whole plant',
        ScanTarget.flower => 'Flower',
      };
}

extension ConditionVerdictX on ConditionVerdict {
  String get title => switch (this) {
        ConditionVerdict.healthy => 'Looks healthy',
        ConditionVerdict.concerns => 'Some concerns',
        ConditionVerdict.needsAttention => 'Needs attention',
      };

  String get subtitle => switch (this) {
        ConditionVerdict.healthy => 'Nothing unusual since last time',
        ConditionVerdict.concerns => 'A few things look off',
        ConditionVerdict.needsAttention => 'Something is clearly wrong',
      };
}

extension PermissionKindX on PermissionKind {
  String get title => switch (this) {
        PermissionKind.location => 'Local weather',
        PermissionKind.camera => 'Camera',
        PermissionKind.photoLibrary => 'Photo library',
      };

  String get body => switch (this) {
        PermissionKind.location =>
          'Allow location access to provide weather-aware care insights.',
        PermissionKind.camera =>
          'Needed to identify plants and log condition photos.',
        PermissionKind.photoLibrary =>
          'Optional — identify a plant from a photo you already took.',
      };
}

/// The botanical silhouette drawn for a species.
///
/// The design renders plants as photographic cut-outs; where a bespoke asset
/// has not been supplied we draw the species' signature leaf shape instead,
/// matching the specification's card artwork.
enum PlantGlyph {
  monstera,
  monsteraAdansonii,
  miniMonstera,
  peaceLily,
  snakePlant,
  fiddleLeaf,
  aloe,
  pothos,
  calathea,
  zzPlant,
  fern,
  rubberPlant,
}

/// Pale grounds behind botanical artwork.
enum GroundPalette { mint, sage }
