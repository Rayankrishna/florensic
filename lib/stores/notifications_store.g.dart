// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$NotificationsStore on _NotificationsStore, Store {
  Computed<bool>? _$isLoadingComputed;

  @override
  bool get isLoading => (_$isLoadingComputed ??= Computed<bool>(
    () => super.isLoading,
    name: '_NotificationsStore.isLoading',
  )).value;
  Computed<int>? _$unreadCountComputed;

  @override
  int get unreadCount => (_$unreadCountComputed ??= Computed<int>(
    () => super.unreadCount,
    name: '_NotificationsStore.unreadCount',
  )).value;
  Computed<bool>? _$hasUnreadComputed;

  @override
  bool get hasUnread => (_$hasUnreadComputed ??= Computed<bool>(
    () => super.hasUnread,
    name: '_NotificationsStore.hasUnread',
  )).value;
  Computed<List<AppNotification>>? _$filteredComputed;

  @override
  List<AppNotification> get filtered =>
      (_$filteredComputed ??= Computed<List<AppNotification>>(
        () => super.filtered,
        name: '_NotificationsStore.filtered',
      )).value;
  Computed<bool>? _$isEmptyComputed;

  @override
  bool get isEmpty => (_$isEmptyComputed ??= Computed<bool>(
    () => super.isEmpty,
    name: '_NotificationsStore.isEmpty',
  )).value;
  Computed<List<MapEntry<String, List<AppNotification>>>>? _$groupedComputed;

  @override
  List<MapEntry<String, List<AppNotification>>> get grouped =>
      (_$groupedComputed ??=
              Computed<List<MapEntry<String, List<AppNotification>>>>(
                () => super.grouped,
                name: '_NotificationsStore.grouped',
              ))
          .value;

  late final _$itemsAtom = Atom(
    name: '_NotificationsStore.items',
    context: context,
  );

  @override
  ObservableList<AppNotification> get items {
    _$itemsAtom.reportRead();
    return super.items;
  }

  @override
  set items(ObservableList<AppNotification> value) {
    _$itemsAtom.reportWrite(value, super.items, () {
      super.items = value;
    });
  }

  late final _$stateAtom = Atom(
    name: '_NotificationsStore.state',
    context: context,
  );

  @override
  LoadState get state {
    _$stateAtom.reportRead();
    return super.state;
  }

  @override
  set state(LoadState value) {
    _$stateAtom.reportWrite(value, super.state, () {
      super.state = value;
    });
  }

  late final _$errorMessageAtom = Atom(
    name: '_NotificationsStore.errorMessage',
    context: context,
  );

  @override
  String? get errorMessage {
    _$errorMessageAtom.reportRead();
    return super.errorMessage;
  }

  @override
  set errorMessage(String? value) {
    _$errorMessageAtom.reportWrite(value, super.errorMessage, () {
      super.errorMessage = value;
    });
  }

  late final _$filterAtom = Atom(
    name: '_NotificationsStore.filter',
    context: context,
  );

  @override
  NotificationFilter get filter {
    _$filterAtom.reportRead();
    return super.filter;
  }

  @override
  set filter(NotificationFilter value) {
    _$filterAtom.reportWrite(value, super.filter, () {
      super.filter = value;
    });
  }

  late final _$loadNotificationsAsyncAction = AsyncAction(
    '_NotificationsStore.loadNotifications',
    context: context,
  );

  @override
  Future<void> loadNotifications({bool force = false}) {
    return _$loadNotificationsAsyncAction.run(
      () => super.loadNotifications(force: force),
    );
  }

  late final _$markAllReadAsyncAction = AsyncAction(
    '_NotificationsStore.markAllRead',
    context: context,
  );

  @override
  Future<void> markAllRead() {
    return _$markAllReadAsyncAction.run(() => super.markAllRead());
  }

  late final _$_NotificationsStoreActionController = ActionController(
    name: '_NotificationsStore',
    context: context,
  );

  @override
  void setFilter(NotificationFilter value) {
    final _$actionInfo = _$_NotificationsStoreActionController.startAction(
      name: '_NotificationsStore.setFilter',
    );
    try {
      return super.setFilter(value);
    } finally {
      _$_NotificationsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
items: ${items},
state: ${state},
errorMessage: ${errorMessage},
filter: ${filter},
isLoading: ${isLoading},
unreadCount: ${unreadCount},
hasUnread: ${hasUnread},
filtered: ${filtered},
isEmpty: ${isEmpty},
grouped: ${grouped}
    ''';
  }
}
