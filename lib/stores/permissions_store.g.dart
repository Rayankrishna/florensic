// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permissions_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$PermissionsStore on _PermissionsStore, Store {
  Computed<bool>? _$hasPhotoLibraryComputed;

  @override
  bool get hasPhotoLibrary => (_$hasPhotoLibraryComputed ??= Computed<bool>(
    () => super.hasPhotoLibrary,
    name: '_PermissionsStore.hasPhotoLibrary',
  )).value;
  Computed<bool>? _$hasCameraComputed;

  @override
  bool get hasCamera => (_$hasCameraComputed ??= Computed<bool>(
    () => super.hasCamera,
    name: '_PermissionsStore.hasCamera',
  )).value;
  Computed<bool>? _$allGrantedComputed;

  @override
  bool get allGranted => (_$allGrantedComputed ??= Computed<bool>(
    () => super.allGranted,
    name: '_PermissionsStore.allGranted',
  )).value;
  Computed<bool>? _$anyAskableComputed;

  @override
  bool get anyAskable => (_$anyAskableComputed ??= Computed<bool>(
    () => super.anyAskable,
    name: '_PermissionsStore.anyAskable',
  )).value;

  late final _$statesAtom = Atom(
    name: '_PermissionsStore.states',
    context: context,
  );

  @override
  ObservableMap<PermissionKind, PermissionState> get states {
    _$statesAtom.reportRead();
    return super.states;
  }

  @override
  set states(ObservableMap<PermissionKind, PermissionState> value) {
    _$statesAtom.reportWrite(value, super.states, () {
      super.states = value;
    });
  }

  late final _$completedAtom = Atom(
    name: '_PermissionsStore.completed',
    context: context,
  );

  @override
  bool get completed {
    _$completedAtom.reportRead();
    return super.completed;
  }

  @override
  set completed(bool value) {
    _$completedAtom.reportWrite(value, super.completed, () {
      super.completed = value;
    });
  }

  late final _$requestingAtom = Atom(
    name: '_PermissionsStore.requesting',
    context: context,
  );

  @override
  PermissionKind? get requesting {
    _$requestingAtom.reportRead();
    return super.requesting;
  }

  @override
  set requesting(PermissionKind? value) {
    _$requestingAtom.reportWrite(value, super.requesting, () {
      super.requesting = value;
    });
  }

  late final _$refreshAsyncAction = AsyncAction(
    '_PermissionsStore.refresh',
    context: context,
  );

  @override
  Future<void> refresh() {
    return _$refreshAsyncAction.run(() => super.refresh());
  }

  late final _$requestAsyncAction = AsyncAction(
    '_PermissionsStore.request',
    context: context,
  );

  @override
  Future<PermissionState> request(PermissionKind kind) {
    return _$requestAsyncAction.run(() => super.request(kind));
  }

  late final _$requestAllAsyncAction = AsyncAction(
    '_PermissionsStore.requestAll',
    context: context,
  );

  @override
  Future<void> requestAll() {
    return _$requestAllAsyncAction.run(() => super.requestAll());
  }

  late final _$completeAsyncAction = AsyncAction(
    '_PermissionsStore.complete',
    context: context,
  );

  @override
  Future<void> complete() {
    return _$completeAsyncAction.run(() => super.complete());
  }

  late final _$_PermissionsStoreActionController = ActionController(
    name: '_PermissionsStore',
    context: context,
  );

  @override
  Future<bool> openSettings() {
    final _$actionInfo = _$_PermissionsStoreActionController.startAction(
      name: '_PermissionsStore.openSettings',
    );
    try {
      return super.openSettings();
    } finally {
      _$_PermissionsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void restore() {
    final _$actionInfo = _$_PermissionsStoreActionController.startAction(
      name: '_PermissionsStore.restore',
    );
    try {
      return super.restore();
    } finally {
      _$_PermissionsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
states: ${states},
completed: ${completed},
requesting: ${requesting},
hasPhotoLibrary: ${hasPhotoLibrary},
hasCamera: ${hasCamera},
allGranted: ${allGranted},
anyAskable: ${anyAskable}
    ''';
  }
}
