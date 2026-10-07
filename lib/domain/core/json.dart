import '../../enum.dart';

/// Small, forgiving readers for the backend's JSON.
///
/// The contract is stable, but a field the app does not know about must never
/// crash a screen — every reader has a sane fallback.
class Json {
  const Json._();

  static Map<String, dynamic> map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static List<Map<String, dynamic>> list(Object? value) => value is List
      ? value.whereType<Map>().map(map).toList(growable: false)
      : const [];

  static List<String> strings(Object? value) => value is List
      ? value.whereType<String>().toList(growable: false)
      : const [];

  static String str(Object? value, [String fallback = '']) =>
      value is String ? value : fallback;

  static int? intOrNull(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value');

  static int integer(Object? value, [int fallback = 0]) =>
      intOrNull(value) ?? fallback;

  static double? doubleOrNull(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value');

  static bool boolean(Object? value, [bool fallback = false]) =>
      value is bool ? value : fallback;

  /// A `*_at` instant: ISO-8601 UTC in, device-local out, for display.
  static DateTime? dateOrNull(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  static DateTime date(Object? value, [DateTime? fallback]) =>
      dateOrNull(value) ?? fallback ?? DateTime.now();

  /// An owner-local calendar date (`YYYY-MM-DD`). The server already dated it
  /// on the owner's day, so it is read as written and never shifted by
  /// `toLocal()`.
  static DateTime? dayOrNull(Object? value) {
    if (value is! String || value.length < 10) return null;
    final parsed = DateTime.tryParse(value.substring(0, 10));
    return parsed == null
        ? null
        : DateTime(parsed.year, parsed.month, parsed.day);
  }

  static DateTime day(Object? value, [DateTime? fallback]) =>
      dayOrNull(value) ?? fallback ?? DateTime.now();

  /// `snake_case` → enum, by name, with a fallback.
  static T enumOf<T extends Enum>(
    Object? value,
    List<T> values,
    T fallback, {
    Map<String, T> aliases = const {},
  }) {
    final raw = str(value);
    if (raw.isEmpty) return fallback;
    final alias = aliases[raw];
    if (alias != null) return alias;
    final camel = raw
        .split('_')
        .indexed
        .map((e) => e.$1 == 0
            ? e.$2
            : e.$2.isEmpty
                ? e.$2
                : e.$2[0].toUpperCase() + e.$2.substring(1))
        .join();
    for (final v in values) {
      if (v.name == camel || v.name == raw) return v;
    }
    return fallback;
  }

  static MetricStatus status(Object? value, [MetricStatus fallback = MetricStatus.good]) =>
      enumOf(value, MetricStatus.values, fallback, aliases: const {
        'ok': MetricStatus.good,
        'good': MetricStatus.good,
        'optimal': MetricStatus.good,
        'watch': MetricStatus.watch,
        'warning': MetricStatus.watch,
        'caution': MetricStatus.watch,
        'bad': MetricStatus.bad,
        'critical': MetricStatus.bad,
        'neutral': MetricStatus.neutral,
        'unknown': MetricStatus.neutral,
      });
}
