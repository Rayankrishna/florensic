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

  late final _$captureAtom = Atom(
    name: '_ScanningStore.capture',
    context: context,
  );

  @override
  Capture? get capture {
    _$captureAtom.reportRead();
    return super.capture;
  }

  @override
  set capture(Capture? value) {
    _$captureAtom.reportWrite(value, super.capture, () {
      super.capture = value;
    });
  }

  late final _$isCapturingAtom = Atom(
    name: '_ScanningStore.isCapturing',
    context: context,
  );

  @override
  bool get isCapturing {
    _$isCapturingAtom.reportRead();
    return super.isCapturing;
  }

  @override
  set isCapturing(bool value) {
    _$isCapturingAtom.reportWrite(value, super.isCapturing, () {
      super.isCapturing = value;
    });
  }

  late final _$needsSettingsAtom = Atom(
    name: '_ScanningStore.needsSettings',
    context: context,
  );

  @override
  bool get needsSettings {
    _$needsSettingsAtom.reportRead();
    return super.needsSettings;
  }

  @override
  set needsSettings(bool value) {
    _$needsSettingsAtom.reportWrite(value, super.needsSettings, () {
      super.needsSettings = value;
    });
  }

  late final _$suggestionQueryAtom = Atom(
    name: '_ScanningStore.suggestionQuery',
    context: context,
  );

  @override
  String get suggestionQuery {
    _$suggestionQueryAtom.reportRead();
    return super.suggestionQuery;
  }

  @override
  set suggestionQuery(String value) {
    _$suggestionQueryAtom.reportWrite(value, super.suggestionQuery, () {
      super.suggestionQuery = value;
    });
  }

  late final _$suggestionsAtom = Atom(
    name: '_ScanningStore.suggestions',
    context: context,
  );

  @override
  ObservableList<SpeciesSuggestion> get suggestions {
    _$suggestionsAtom.reportRead();
    return super.suggestions;
  }

  @override
  set suggestions(ObservableList<SpeciesSuggestion> value) {
    _$suggestionsAtom.reportWrite(value, super.suggestions, () {
      super.suggestions = value;
    });
  }

  late final _$isSuggestingAtom = Atom(
    name: '_ScanningStore.isSuggesting',
    context: context,
  );

  @override
  bool get isSuggesting {
    _$isSuggestingAtom.reportRead();
    return super.isSuggesting;
  }

  @override
  set isSuggesting(bool value) {
    _$isSuggestingAtom.reportWrite(value, super.isSuggesting, () {
      super.isSuggesting = value;
    });
  }

  late final _$isCorrectingAtom = Atom(
    name: '_ScanningStore.isCorrecting',
    context: context,
  );

  @override
  bool get isCorrecting {
    _$isCorrectingAtom.reportRead();
    return super.isCorrecting;
  }

  @override
  set isCorrecting(bool value) {
    _$isCorrectingAtom.reportWrite(value, super.isCorrecting, () {
      super.isCorrecting = value;
    });
  }

  late final _$correctionErrorAtom = Atom(
    name: '_ScanningStore.correctionError',
    context: context,
  );

  @override
  String? get correctionError {
    _$correctionErrorAtom.reportRead();
    return super.correctionError;
  }

  @override
  set correctionError(String? value) {
    _$correctionErrorAtom.reportWrite(value, super.correctionError, () {
      super.correctionError = value;
    });
  }

  late final _$suggestSpeciesAsyncAction = AsyncAction(
    '_ScanningStore.suggestSpecies',
    context: context,
  );

  @override
  Future<void> suggestSpecies(String query) {
    return _$suggestSpeciesAsyncAction.run(() => super.suggestSpecies(query));
  }

  late final _$correctSpeciesAsyncAction = AsyncAction(
    '_ScanningStore.correctSpecies',
    context: context,
  );

  @override
  Future<bool> correctSpecies(SpeciesSuggestion pick) {
    return _$correctSpeciesAsyncAction.run(() => super.correctSpecies(pick));
  }

  late final _$scanPlantAsyncAction = AsyncAction(
    '_ScanningStore.scanPlant',
    context: context,
  );

  @override
  Future<void> scanPlant() {
    return _$scanPlantAsyncAction.run(() => super.scanPlant());
  }

  late final _$identifyPhotoAsyncAction = AsyncAction(
    '_ScanningStore.identifyPhoto',
    context: context,
  );

  @override
  Future<void> identifyPhoto(File file) {
    return _$identifyPhotoAsyncAction.run(() => super.identifyPhoto(file));
  }

  late final _$selectImageAsyncAction = AsyncAction(
    '_ScanningStore.selectImage',
    context: context,
  );

  @override
  Future<void> selectImage() {
    return _$selectImageAsyncAction.run(() => super.selectImage());
  }

  late final _$_takePhotoAsyncAction = AsyncAction(
    '_ScanningStore._takePhoto',
    context: context,
  );

  @override
  Future<Capture?> _takePhoto({required bool fromCamera}) {
    return _$_takePhotoAsyncAction.run(
      () => super._takePhoto(fromCamera: fromCamera),
    );
  }

  late final _$_identifyAsyncAction = AsyncAction(
    '_ScanningStore._identify',
    context: context,
  );

  @override
  Future<void> _identify() {
    return _$_identifyAsyncAction.run(() => super._identify());
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
  void clearSuggestions() {
    final _$actionInfo = _$_ScanningStoreActionController.startAction(
      name: '_ScanningStore.clearSuggestions',
    );
    try {
      return super.clearSuggestions();
    } finally {
      _$_ScanningStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void useAlternative(IdentificationAlternative alt) {
    final _$actionInfo = _$_ScanningStoreActionController.startAction(
      name: '_ScanningStore.useAlternative',
    );
    try {
      return super.useAlternative(alt);
    } finally {
      _$_ScanningStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void revertCorrection() {
    final _$actionInfo = _$_ScanningStoreActionController.startAction(
      name: '_ScanningStore.revertCorrection',
    );
    try {
      return super.revertCorrection();
    } finally {
      _$_ScanningStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  Future<void> openSettings() {
    final _$actionInfo = _$_ScanningStoreActionController.startAction(
      name: '_ScanningStore.openSettings',
    );
    try {
      return super.openSettings();
    } finally {
      _$_ScanningStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  Plant? addToCollection({String? nickname}) {
    final _$actionInfo = _$_ScanningStoreActionController.startAction(
      name: '_ScanningStore.addToCollection',
    );
    try {
      return super.addToCollection(nickname: nickname);
    } finally {
      _$_ScanningStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
status: ${status},
target: ${target},
result: ${result},
errorMessage: ${errorMessage},
capture: ${capture},
isCapturing: ${isCapturing},
needsSettings: ${needsSettings},
suggestionQuery: ${suggestionQuery},
suggestions: ${suggestions},
isSuggesting: ${isSuggesting},
isCorrecting: ${isCorrecting},
correctionError: ${correctionError},
isScanning: ${isScanning},
hasMatch: ${hasMatch},
confidence: ${confidence},
photoLibraryEnabled: ${photoLibraryEnabled},
showFailureSheet: ${showFailureSheet},
failureTitle: ${failureTitle}
    ''';
  }
}
