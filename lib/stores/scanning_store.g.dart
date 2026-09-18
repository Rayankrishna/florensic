// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scanning_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ScanningStore on _ScanningStore, Store {
  Computed<bool>? _$isScanningComputed;

  @override
  bool get isScanning => (_$isScanningComputed ??= Computed<bool>(
    () => super.isScanning,
    name: '_ScanningStore.isScanning',
  )).value;
  Computed<bool>? _$hasMatchComputed;

  @override
  bool get hasMatch => (_$hasMatchComputed ??= Computed<bool>(
    () => super.hasMatch,
    name: '_ScanningStore.hasMatch',
  )).value;
  Computed<int>? _$confidenceComputed;

  @override
  int get confidence => (_$confidenceComputed ??= Computed<int>(
    () => super.confidence,
    name: '_ScanningStore.confidence',
  )).value;
  Computed<bool>? _$photoLibraryEnabledComputed;

  @override
  bool get photoLibraryEnabled =>
      (_$photoLibraryEnabledComputed ??= Computed<bool>(
        () => super.photoLibraryEnabled,
        name: '_ScanningStore.photoLibraryEnabled',
      )).value;
  Computed<bool>? _$showFailureSheetComputed;

  @override
  bool get showFailureSheet => (_$showFailureSheetComputed ??= Computed<bool>(
    () => super.showFailureSheet,
    name: '_ScanningStore.showFailureSheet',
  )).value;
  Computed<String>? _$failureTitleComputed;

  @override
  String get failureTitle => (_$failureTitleComputed ??= Computed<String>(
    () => super.failureTitle,
    name: '_ScanningStore.failureTitle',
  )).value;

  late final _$statusAtom = Atom(
    name: '_ScanningStore.status',
    context: context,
  );

  @override
  ScanStatus get status {
    _$statusAtom.reportRead();
    return super.status;
  }

  @override
  set status(ScanStatus value) {
    _$statusAtom.reportWrite(value, super.status, () {
      super.status = value;
    });
  }

  late final _$targetAtom = Atom(
    name: '_ScanningStore.target',
    context: context,
  );

  @override
  ScanTarget get target {
    _$targetAtom.reportRead();
    return super.target;
  }

  @override
  set target(ScanTarget value) {
    _$targetAtom.reportWrite(value, super.target, () {
      super.target = value;
    });
  }

  late final _$torchOnAtom = Atom(
    name: '_ScanningStore.torchOn',
    context: context,
  );

  @override
  bool get torchOn {
    _$torchOnAtom.reportRead();
    return super.torchOn;
  }

  @override
  set torchOn(bool value) {
    _$torchOnAtom.reportWrite(value, super.torchOn, () {
      super.torchOn = value;
    });
  }

  late final _$resultAtom = Atom(
    name: '_ScanningStore.result',
    context: context,
  );

  @override
  IdentificationResult? get result {
    _$resultAtom.reportRead();
    return super.result;
  }

  @override
  set result(IdentificationResult? value) {
    _$resultAtom.reportWrite(value, super.result, () {
      super.result = value;
    });
  }

  late final _$errorMessageAtom = Atom(
    name: '_ScanningStore.errorMessage',
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

  late final _$isAddingAtom = Atom(
    name: '_ScanningStore.isAdding',
    context: context,
  );

  @override
  bool get isAdding {
    _$isAddingAtom.reportRead();
    return super.isAdding;
  }

  @override
  set isAdding(bool value) {
    _$isAddingAtom.reportWrite(value, super.isAdding, () {
      super.isAdding = value;
    });
  }

  late final _$scanPlantAsyncAction = AsyncAction(
    '_ScanningStore.scanPlant',
    context: context,
  );

  @override
  Future<void> scanPlant() {
    return _$scanPlantAsyncAction.run(() => super.scanPlant());
  }

  late final _$selectImageAsyncAction = AsyncAction(
    '_ScanningStore.selectImage',
    context: context,
  );

  @override
  Future<void> selectImage() {
    return _$selectImageAsyncAction.run(() => super.selectImage());
  }

  late final _$addToCollectionAsyncAction = AsyncAction(
    '_ScanningStore.addToCollection',
    context: context,
  );

  @override
  Future<Plant?> addToCollection({String? nickname}) {
    return _$addToCollectionAsyncAction.run(
      () => super.addToCollection(nickname: nickname),
    );
  }

  late final _$_ScanningStoreActionController = ActionController(
    name: '_ScanningStore',
    context: context,
  );

  @override
  void setTarget(ScanTarget value) {
    final _$actionInfo = _$_ScanningStoreActionController.startAction(
      name: '_ScanningStore.setTarget',
    );
    try {
      return super.setTarget(value);
    } finally {
      _$_ScanningStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleTorch() {
    final _$actionInfo = _$_ScanningStoreActionController.startAction(
      name: '_ScanningStore.toggleTorch',
    );
    try {
      return super.toggleTorch();
    } finally {
      _$_ScanningStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void resetScan() {
    final _$actionInfo = _$_ScanningStoreActionController.startAction(
      name: '_ScanningStore.resetScan',
    );
    try {
      return super.resetScan();
    } finally {
      _$_ScanningStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void simulateOffline(bool value) {
    final _$actionInfo = _$_ScanningStoreActionController.startAction(
      name: '_ScanningStore.simulateOffline',
    );
    try {
      return super.simulateOffline(value);
    } finally {
      _$_ScanningStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void simulateNoMatch(bool value) {
    final _$actionInfo = _$_ScanningStoreActionController.startAction(
      name: '_ScanningStore.simulateNoMatch',
    );
    try {
      return super.simulateNoMatch(value);
    } finally {
      _$_ScanningStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
status: ${status},
target: ${target},
torchOn: ${torchOn},
result: ${result},
errorMessage: ${errorMessage},
isAdding: ${isAdding},
isScanning: ${isScanning},
hasMatch: ${hasMatch},
confidence: ${confidence},
photoLibraryEnabled: ${photoLibraryEnabled},
showFailureSheet: ${showFailureSheet},
failureTitle: ${failureTitle}
    ''';
  }
}
