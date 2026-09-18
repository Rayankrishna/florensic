import 'package:mobx/mobx.dart';

import '../enum.dart';
import '../key.dart';
import '../storage_manager.dart';

part 'permissions_store.g.dart';

class PermissionsStore = _PermissionsStore with _$PermissionsStore;

abstract class _PermissionsStore with Store {
  _PermissionsStore(this._storage);

  final StorageManager _storage;

  /// Defaults mirror the specification: the first three on, photo library off.
  @observable
  ObservableMap<PermissionKind, bool> granted =
      ObservableMap<PermissionKind, bool>.of({
    PermissionKind.location: true,
    PermissionKind.reminders: true,
    PermissionKind.camera: true,
    PermissionKind.photoLibrary: false,
  });

  @observable
  bool completed = false;

  @computed
  bool get hasPhotoLibrary => granted[PermissionKind.photoLibrary] ?? false;

  @computed
  bool get hasCamera => granted[PermissionKind.camera] ?? false;

  @action
  void toggle(PermissionKind kind) {
    granted[kind] = !(granted[kind] ?? false);
  }

  @action
  void set(PermissionKind kind, bool value) => granted[kind] = value;

  @action
  Future<void> complete() async {
    completed = true;
    await _storage.setBool(StorageKeys.permissionsComplete, true);
    await _storage.setStringList(
      StorageKeys.grantedPermissions,
      granted.entries.where((e) => e.value).map((e) => e.key.name).toList(),
    );
  }

  @action
  void restore() {
    completed = _storage.getBool(StorageKeys.permissionsComplete);
    if (!completed) return;
    final saved = _storage.getStringList(StorageKeys.grantedPermissions).toSet();
    for (final kind in PermissionKind.values) {
      granted[kind] = saved.contains(kind.name);
    }
  }
}
