import 'app_clock.dart';

/// Date and duration formatting, in the voice the design uses.
class AppDate {
  const AppDate._();

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const List<String> _weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  static const List<String> _weekdayInitials = [
    'M', 'T', 'W', 'T', 'F', 'S', 'S',
  ];

  static const List<String> _monthsFull = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static String weekdayShort(DateTime d) => _weekdays[d.weekday - 1];

  static String weekdayInitial(DateTime d) => _weekdayInitials[d.weekday - 1];

  static String monthFull(DateTime d) => _monthsFull[d.month - 1];

  /// `18 Sep`
  static String dayMonth(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  /// `Fri 18 Sep`
  static String weekdayDayMonth(DateTime d) =>
      '${weekdayShort(d)} ${d.day} ${_months[d.month - 1]}';

  /// `1 Oct`
  static String shortDate(DateTime d) => dayMonth(d);

  /// `07:40`
  static String time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  /// `7:40` — as shown in the design's care list.
  static String looseTime(DateTime d) =>
      '${d.hour}:${d.minute.toString().padLeft(2, '0')}';

  /// `Tue 16 Sep, 07:40`
  static String eventStamp(DateTime d) =>
      '${weekdayDayMonth(d)}, ${time(d)}';

  /// `2 days ago`, `today`, `yesterday`.
  static String relativeDays(int days) {
    if (days <= 0) return 'today';
    if (days == 1) return 'yesterday';
    return '$days days ago';
  }

  /// `Tomorrow`, `Today`, `In 5 days`, `4 days late`.
  static String relativeDue(int days) {
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days > 1) return 'In $days days';
    if (days == -1) return '1 day late';
    return '${-days} days late';
  }

  /// The Monday-first week containing [anchor].
  static List<DateTime> weekOf(DateTime anchor) {
    final start = anchor.subtract(Duration(days: anchor.weekday - 1));
    return List.generate(
      7,
      (i) => DateTime(start.year, start.month, start.day + i),
    );
  }

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// `Good morning` / `Good afternoon` / `Good evening`.
  static String greeting([DateTime? now]) {
    final h = (now ?? AppClock.now()).hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }
}
