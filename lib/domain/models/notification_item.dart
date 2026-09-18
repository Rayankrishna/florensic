import '../../enum.dart';

/// One row in the Notifications list.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.detail,
    required this.kind,
    required this.group,
    required this.unread,
    this.plantId,
  });

  final String id;
  final String title;
  final String detail;
  final NotificationKind kind;

  /// `TODAY` or `THIS WEEK`.
  final String group;
  final bool unread;
  final String? plantId;

  bool matches(NotificationFilter filter) => switch (filter) {
        NotificationFilter.all => true,
        NotificationFilter.watering => kind == NotificationKind.watering,
        NotificationFilter.checkIns => kind == NotificationKind.conditionUpdate ||
            kind == NotificationKind.checkInMissed,
        NotificationFilter.environment => kind == NotificationKind.environment,
      };

  AppNotification copyWith({bool? unread}) => AppNotification(
        id: id,
        title: title,
        detail: detail,
        kind: kind,
        group: group,
        unread: unread ?? this.unread,
        plantId: plantId,
      );
}
