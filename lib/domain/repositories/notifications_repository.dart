import '../../enum.dart';
import '../models/notification_item.dart';
import 'mock/mock_api_client.dart';

abstract class NotificationsRepository {
  Future<List<AppNotification>> loadNotifications();

  Future<void> markAllRead();
}

class MockNotificationsRepository implements NotificationsRepository {
  MockNotificationsRepository(this._client);

  final MockApiClient _client;

  List<AppNotification>? _items;

  List<AppNotification> get _seed => _items ??= [
        const AppNotification(
          id: 'n1',
          title: 'Your Monstera needs a condition update.',
          detail: 'Due today · 2h ago',
          kind: NotificationKind.conditionUpdate,
          group: 'TODAY',
          unread: true,
          plantId: 'p-monstera',
        ),
        const AppNotification(
          id: 'n2',
          title: 'Your Aloe Vera may need watering today.',
          detail: 'Watering reminder · 08:00',
          kind: NotificationKind.watering,
          group: 'TODAY',
          unread: true,
          plantId: 'p-aloe-vera',
        ),
        const AppNotification(
          id: 'n3',
          title: 'Warm spell through Friday.',
          detail: 'Environmental alert · 07:15',
          kind: NotificationKind.environment,
          group: 'TODAY',
          unread: false,
        ),
        const AppNotification(
          id: 'n4',
          title: 'Snake Plant health rose to 91.',
          detail: 'Health change · Tue',
          kind: NotificationKind.healthChange,
          group: 'THIS WEEK',
          unread: false,
          plantId: 'p-snake-plant',
        ),
        const AppNotification(
          id: 'n5',
          title: 'Parlour Palm care status paused.',
          detail: 'Check-in missed · Mon',
          kind: NotificationKind.checkInMissed,
          group: 'THIS WEEK',
          unread: false,
          plantId: 'p-parlour-palm',
        ),
        const AppNotification(
          id: 'n6',
          title: '42 new species added to the Pokedex.',
          detail: 'App update · Sun',
          kind: NotificationKind.appUpdate,
          group: 'THIS WEEK',
          unread: false,
        ),
      ];

  @override
  Future<List<AppNotification>> loadNotifications() => _client.send(
        '/notifications',
        () => List<AppNotification>.unmodifiable(_seed),
        failsWhenOffline: false,
      );

  @override
  Future<void> markAllRead() => _client.send(
        '/notifications/read',
        () {
          final items = _seed;
          for (var i = 0; i < items.length; i++) {
            items[i] = items[i].copyWith(unread: false);
          }
        },
        failsWhenOffline: false,
      );
}
