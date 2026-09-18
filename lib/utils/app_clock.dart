/// The app's single source of "now".
///
/// Production leaves [now] at the system clock; tests pin it so schedules,
/// calendars and timestamps render deterministically.
class AppClock {
  const AppClock._();

  static DateTime Function() now = DateTime.now;

  static DateTime today() {
    final n = now();
    return DateTime(n.year, n.month, n.day);
  }
}
