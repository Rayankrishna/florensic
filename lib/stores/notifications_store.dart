import 'package:mobx/mobx.dart';

import '../domain/models/notification_item.dart';
import '../domain/repositories/notifications_repository.dart';
import '../enum.dart';
import '../interceptors/api_interceptor.dart';
import '../utils/app_log.dart';

part 'notifications_store.g.dart';

class NotificationsStore = _NotificationsStore with _$NotificationsStore;

abstract class _NotificationsStore with Store {
  _NotificationsStore(this._repository);

  final NotificationsRepository _repository;

  @observable
  ObservableList<AppNotification> items = ObservableList<AppNotification>();

  @observable
  LoadState state = LoadState.idle;

  @observable
  String? errorMessage;

  @observable
  NotificationFilter filter = NotificationFilter.all;

  @computed
  bool get isLoading => state == LoadState.loading;

  @computed
  int get unreadCount => items.where((n) => n.unread).length;

  @computed
  bool get hasUnread => unreadCount > 0;

  @computed
  List<AppNotification> get filtered =>
      items.where((n) => n.matches(filter)).toList(growable: false);

  @computed
  bool get isEmpty => state == LoadState.ready && filtered.isEmpty;

  /// Grouped as the design shows: `TODAY`, then `THIS WEEK`.
  @computed
  List<MapEntry<String, List<AppNotification>>> get grouped {
    final order = <String>[];
    final map = <String, List<AppNotification>>{};
    for (final n in filtered) {
      if (!map.containsKey(n.group)) {
        map[n.group] = [];
        order.add(n.group);
      }
      map[n.group]!.add(n);
    }
    return order.map((g) => MapEntry(g, map[g]!)).toList(growable: false);
  }

  @action
  void setFilter(NotificationFilter value) => filter = value;

  @action
  Future<void> loadNotifications({bool force = false}) async {
    if (state == LoadState.loading) return;
    if (!force && state == LoadState.ready) return;
    state = LoadState.loading;
    errorMessage = null;

    List<AppNotification> resp;
    try {
      resp = await _repository.loadNotifications();
    } catch (e, stack) {
      AppLog.e('loading notifications failed',
          name: 'notifications', error: e, stackTrace: stack);
      runInAction(() {
        errorMessage = e is ApiException ? e.message : e.toString();
        if (items.isEmpty) state = LoadState.error;
      });
      return;
    }

    runInAction(() {
      items = ObservableList<AppNotification>.of(resp);
      state = LoadState.ready;
    });
  }

  @action
  Future<void> markAllRead() async {
    for (var i = 0; i < items.length; i++) {
      items[i] = items[i].copyWith(unread: false);
    }
    await _repository.markAllRead();
  }
}
