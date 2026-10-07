import '../models/notification_item.dart';

abstract class NotificationsRepository {
  Future<List<AppNotification>> loadNotifications();

  Future<void> markAllRead();
}

/// There is no notifications endpoint yet.
///
/// Rather than show a fabricated feed, this returns nothing and the screen
/// renders its empty state. Everything the feed would carry is already
/// visible elsewhere: care history on the plant, `needs attention` on home,
/// and new insights on Insights.
class UnavailableNotificationsRepository implements NotificationsRepository {
  const UnavailableNotificationsRepository();

  @override
  Future<List<AppNotification>> loadNotifications() async => const [];

  @override
  Future<void> markAllRead() async {}
}
