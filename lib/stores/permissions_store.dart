import 'dart:io';

import 'package:mobx/mobx.dart';
import 'package:permission_handler/permission_handler.dart';

import '../enum.dart';
import '../key.dart';
import '../storage_manager.dart';
import '../utils/app_log.dart';

part 'permissions_store.g.dart';

class PermissionsStore = _PermissionsStore with _$PermissionsStore;

/// The platform permissions the app asks for, read from the OS rather than
/// remembered: what the keeper allowed in Settings is the truth, and the
/// screen only ever shows that.
abstract class _PermissionsStore with Store {
  _PermissionsStore(this._storage);

  final StorageManager _storage;

  /// What the OS currently allows, per kind. [PermissionState.unknown] until
  /// [refresh] has run.
  @observable
  ObservableMap<PermissionKind, PermissionState> states =
      ObservableMap<PermissionKind, PermissionState>.of({
    for (final kind in PermissionKind.values) kind: PermissionState.unknown,
  });

  /// The permissions step has been seen once (allowed or skipped).
  @observable
  bool completed = false;

  /// The kind whose system prompt is on screen.
  @observable
  PermissionKind? requesting;

  @computed
  bool get hasPhotoLibrary =>
      states[PermissionKind.photoLibrary] == PermissionState.granted;

  @computed
  bool get hasCamera => states[PermissionKind.camera] == PermissionState.granted;

  @computed
  bool get allGranted => PermissionKind.values
      .every((kind) => states[kind] == PermissionState.granted);

  /// Anything the system prompt can still be shown for.
  @computed
  bool get anyAskable => PermissionKind.values.any((kind) =>
      states[kind] == PermissionState.denied ||
      states[kind] == PermissionState.unknown);

  /// Reads every status from the platform.
  @action
  Future<void> refresh() async {
    for (final kind in PermissionKind.values) {
      final state = await _read(kind);
      runInAction(() => states[kind] = state);
    }
  }

  /// Shows the system prompt for [kind], or Settings once it has been
  /// refused for good. Returns the state afterwards.
  @action
  Future<PermissionState> request(PermissionKind kind) async {
    if (states[kind] == PermissionState.blocked) {
      await openAppSettings();
      return PermissionState.blocked;
    }
    requesting = kind;
    try {
      var state = _stateOf(await _permissionFor(kind).request());
      // Android 12 and below expose the library as storage.
      if (kind == PermissionKind.photoLibrary &&
          state != PermissionState.granted &&
          Platform.isAndroid) {
        state = _stateOf(await Permission.storage.request());
      }
      AppLog.i('${kind.name} permission: ${state.name}', name: 'permissions');
      runInAction(() => states[kind] = state);
      return state;
    } finally {
      runInAction(() => requesting = null);
    }
  }

  /// Asks for everything that can still be asked for, one prompt after
  /// another. Anything refused for good is left for Settings.
  @action
  Future<void> requestAll() async {
    for (final kind in PermissionKind.values) {
      final state = states[kind];
      if (state == PermissionState.denied || state == PermissionState.unknown) {
        await request(kind);
      }
    }
  }

  @action
  Future<bool> openSettings() => openAppSettings();

  @action
  Future<void> complete() async {
    completed = true;
    await _storage.setBool(StorageKeys.permissionsComplete, true);
  }

  @action
  void restore() {
    completed = _storage.getBool(StorageKeys.permissionsComplete);
  }

  Future<PermissionState> _read(PermissionKind kind) async {
    try {
      var state = _stateOf(await _permissionFor(kind).status);
      if (kind == PermissionKind.photoLibrary &&
          state != PermissionState.granted &&
          Platform.isAndroid) {
        final storage = _stateOf(await Permission.storage.status);
        if (storage == PermissionState.granted) state = storage;
      }
      return state;
    } catch (e) {
      // No plugin on this build yet; the screen keeps asking.
      AppLog.w('could not read ${kind.name} permission: $e',
          name: 'permissions');
      return PermissionState.unknown;
    }
  }

  static Permission _permissionFor(PermissionKind kind) => switch (kind) {
        PermissionKind.camera => Permission.camera,
        PermissionKind.photoLibrary => Permission.photos,
        PermissionKind.location => Permission.locationWhenInUse,
      };

  /// Limited photo access (iOS) is enough to pick a photo, so it counts.
  static PermissionState _stateOf(PermissionStatus status) {
    if (status.isGranted || status.isLimited) return PermissionState.granted;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return PermissionState.blocked;
    }
    return PermissionState.denied;
  }
}
