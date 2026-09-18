// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'condition_update_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ConditionUpdateStore on _ConditionUpdateStore, Store {
  Computed<bool>? _$canContinueFromReviewComputed;

  @override
  bool get canContinueFromReview =>
      (_$canContinueFromReviewComputed ??= Computed<bool>(
        () => super.canContinueFromReview,
        name: '_ConditionUpdateStore.canContinueFromReview',
      )).value;
  Computed<bool>? _$canSaveComputed;

  @override
  bool get canSave => (_$canSaveComputed ??= Computed<bool>(
    () => super.canSave,
    name: '_ConditionUpdateStore.canSave',
  )).value;
  Computed<String>? _$stepTitleComputed;

  @override
  String get stepTitle => (_$stepTitleComputed ??= Computed<String>(
    () => super.stepTitle,
    name: '_ConditionUpdateStore.stepTitle',
  )).value;
  Computed<String>? _$framingNoteComputed;

  @override
  String get framingNote => (_$framingNoteComputed ??= Computed<String>(
    () => super.framingNote,
    name: '_ConditionUpdateStore.framingNote',
  )).value;
  Computed<String>? _$comparedWithComputed;

  @override
  String get comparedWith => (_$comparedWithComputed ??= Computed<String>(
    () => super.comparedWith,
    name: '_ConditionUpdateStore.comparedWith',
  )).value;
  Computed<String>? _$visibleChangeComputed;

  @override
  String get visibleChange => (_$visibleChangeComputed ??= Computed<String>(
    () => super.visibleChange,
    name: '_ConditionUpdateStore.visibleChange',
  )).value;

  late final _$plantAtom = Atom(
    name: '_ConditionUpdateStore.plant',
    context: context,
  );

  @override
  Plant? get plant {
    _$plantAtom.reportRead();
    return super.plant;
  }

  @override
  set plant(Plant? value) {
    _$plantAtom.reportWrite(value, super.plant, () {
      super.plant = value;
    });
  }

  late final _$stepAtom = Atom(
    name: '_ConditionUpdateStore.step',
    context: context,
  );

  @override
  int get step {
    _$stepAtom.reportRead();
    return super.step;
  }

  @override
  set step(int value) {
    _$stepAtom.reportWrite(value, super.step, () {
      super.step = value;
    });
  }

  late final _$isCapturingAtom = Atom(
    name: '_ConditionUpdateStore.isCapturing',
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

  late final _$hasPhotoAtom = Atom(
    name: '_ConditionUpdateStore.hasPhoto',
    context: context,
  );

  @override
  bool get hasPhoto {
    _$hasPhotoAtom.reportRead();
    return super.hasPhoto;
  }

  @override
  set hasPhoto(bool value) {
    _$hasPhotoAtom.reportWrite(value, super.hasPhoto, () {
      super.hasPhoto = value;
    });
  }

  late final _$capturedAtAtom = Atom(
    name: '_ConditionUpdateStore.capturedAt',
    context: context,
  );

  @override
  DateTime? get capturedAt {
    _$capturedAtAtom.reportRead();
    return super.capturedAt;
  }

  @override
  set capturedAt(DateTime? value) {
    _$capturedAtAtom.reportWrite(value, super.capturedAt, () {
      super.capturedAt = value;
    });
  }

  late final _$verdictAtom = Atom(
    name: '_ConditionUpdateStore.verdict',
    context: context,
  );

  @override
  ConditionVerdict? get verdict {
    _$verdictAtom.reportRead();
    return super.verdict;
  }

  @override
  set verdict(ConditionVerdict? value) {
    _$verdictAtom.reportWrite(value, super.verdict, () {
      super.verdict = value;
    });
  }

  late final _$observationsAtom = Atom(
    name: '_ConditionUpdateStore.observations',
    context: context,
  );

  @override
  ObservableList<String> get observations {
    _$observationsAtom.reportRead();
    return super.observations;
  }

  @override
  set observations(ObservableList<String> value) {
    _$observationsAtom.reportWrite(value, super.observations, () {
      super.observations = value;
    });
  }

  late final _$noteAtom = Atom(
    name: '_ConditionUpdateStore.note',
    context: context,
  );

  @override
  String get note {
    _$noteAtom.reportRead();
    return super.note;
  }

  @override
  set note(String value) {
    _$noteAtom.reportWrite(value, super.note, () {
      super.note = value;
    });
  }

  late final _$isSavingAtom = Atom(
    name: '_ConditionUpdateStore.isSaving',
    context: context,
  );

  @override
  bool get isSaving {
    _$isSavingAtom.reportRead();
    return super.isSaving;
  }

  @override
  set isSaving(bool value) {
    _$isSavingAtom.reportWrite(value, super.isSaving, () {
      super.isSaving = value;
    });
  }

  late final _$errorMessageAtom = Atom(
    name: '_ConditionUpdateStore.errorMessage',
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

  late final _$newScoreAtom = Atom(
    name: '_ConditionUpdateStore.newScore',
    context: context,
  );

  @override
  int? get newScore {
    _$newScoreAtom.reportRead();
    return super.newScore;
  }

  @override
  set newScore(int? value) {
    _$newScoreAtom.reportWrite(value, super.newScore, () {
      super.newScore = value;
    });
  }

  late final _$scoreDeltaAtom = Atom(
    name: '_ConditionUpdateStore.scoreDelta',
    context: context,
  );

  @override
  int get scoreDelta {
    _$scoreDeltaAtom.reportRead();
    return super.scoreDelta;
  }

  @override
  set scoreDelta(int value) {
    _$scoreDeltaAtom.reportWrite(value, super.scoreDelta, () {
      super.scoreDelta = value;
    });
  }

  late final _$nextCheckInAtom = Atom(
    name: '_ConditionUpdateStore.nextCheckIn',
    context: context,
  );

  @override
  DateTime? get nextCheckIn {
    _$nextCheckInAtom.reportRead();
    return super.nextCheckIn;
  }

  @override
  set nextCheckIn(DateTime? value) {
    _$nextCheckInAtom.reportWrite(value, super.nextCheckIn, () {
      super.nextCheckIn = value;
    });
  }

  late final _$captureAsyncAction = AsyncAction(
    '_ConditionUpdateStore.capture',
    context: context,
  );

  @override
  Future<void> capture() {
    return _$captureAsyncAction.run(() => super.capture());
  }

  late final _$saveAsyncAction = AsyncAction(
    '_ConditionUpdateStore.save',
    context: context,
  );

  @override
  Future<bool> save() {
    return _$saveAsyncAction.run(() => super.save());
  }

  late final _$_ConditionUpdateStoreActionController = ActionController(
    name: '_ConditionUpdateStore',
    context: context,
  );

  @override
  void start(Plant value) {
    final _$actionInfo = _$_ConditionUpdateStoreActionController.startAction(
      name: '_ConditionUpdateStore.start',
    );
    try {
      return super.start(value);
    } finally {
      _$_ConditionUpdateStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void retake() {
    final _$actionInfo = _$_ConditionUpdateStoreActionController.startAction(
      name: '_ConditionUpdateStore.retake',
    );
    try {
      return super.retake();
    } finally {
      _$_ConditionUpdateStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void next() {
    final _$actionInfo = _$_ConditionUpdateStoreActionController.startAction(
      name: '_ConditionUpdateStore.next',
    );
    try {
      return super.next();
    } finally {
      _$_ConditionUpdateStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void back() {
    final _$actionInfo = _$_ConditionUpdateStoreActionController.startAction(
      name: '_ConditionUpdateStore.back',
    );
    try {
      return super.back();
    } finally {
      _$_ConditionUpdateStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setVerdict(ConditionVerdict value) {
    final _$actionInfo = _$_ConditionUpdateStoreActionController.startAction(
      name: '_ConditionUpdateStore.setVerdict',
    );
    try {
      return super.setVerdict(value);
    } finally {
      _$_ConditionUpdateStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleObservation(String value) {
    final _$actionInfo = _$_ConditionUpdateStoreActionController.startAction(
      name: '_ConditionUpdateStore.toggleObservation',
    );
    try {
      return super.toggleObservation(value);
    } finally {
      _$_ConditionUpdateStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setNote(String value) {
    final _$actionInfo = _$_ConditionUpdateStoreActionController.startAction(
      name: '_ConditionUpdateStore.setNote',
    );
    try {
      return super.setNote(value);
    } finally {
      _$_ConditionUpdateStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
plant: ${plant},
step: ${step},
isCapturing: ${isCapturing},
hasPhoto: ${hasPhoto},
capturedAt: ${capturedAt},
verdict: ${verdict},
observations: ${observations},
note: ${note},
isSaving: ${isSaving},
errorMessage: ${errorMessage},
newScore: ${newScore},
scoreDelta: ${scoreDelta},
nextCheckIn: ${nextCheckIn},
canContinueFromReview: ${canContinueFromReview},
canSave: ${canSave},
stepTitle: ${stepTitle},
framingNote: ${framingNote},
comparedWith: ${comparedWith},
visibleChange: ${visibleChange}
    ''';
  }
}
