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

  late final _$grantedAtom = Atom(
    name: '_PermissionsStore.granted',
    context: context,
  );

  @override
  ObservableMap<PermissionKind, bool> get granted {
    _$grantedAtom.reportRead();
    return super.granted;
  }

  @override
  set granted(ObservableMap<PermissionKind, bool> value) {
    _$grantedAtom.reportWrite(value, super.granted, () {
      super.granted = value;
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
  void toggle(PermissionKind kind) {
    final _$actionInfo = _$_PermissionsStoreActionController.startAction(
      name: '_PermissionsStore.toggle',
    );
    try {
      return super.toggle(kind);
    } finally {
      _$_PermissionsStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void set(PermissionKind kind, bool value) {
    final _$actionInfo = _$_PermissionsStoreActionController.startAction(
      name: '_PermissionsStore.set',
    );
    try {
      return super.set(kind, value);
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
granted: ${granted},
completed: ${completed},
hasPhotoLibrary: ${hasPhotoLibrary},
hasCamera: ${hasCamera}
    ''';
  }
}
