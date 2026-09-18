// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$OnboardingStore on _OnboardingStore, Store {
  Computed<bool>? _$isLastStepComputed;

  @override
  bool get isLastStep => (_$isLastStepComputed ??= Computed<bool>(
    () => super.isLastStep,
    name: '_OnboardingStore.isLastStep',
  )).value;
  Computed<String>? _$stepLabelComputed;

  @override
  String get stepLabel => (_$stepLabelComputed ??= Computed<String>(
    () => super.stepLabel,
    name: '_OnboardingStore.stepLabel',
  )).value;
  Computed<double>? _$progressComputed;

  @override
  double get progress => (_$progressComputed ??= Computed<double>(
    () => super.progress,
    name: '_OnboardingStore.progress',
  )).value;

  late final _$currentStepAtom = Atom(
    name: '_OnboardingStore.currentStep',
    context: context,
  );

  @override
  int get currentStep {
    _$currentStepAtom.reportRead();
    return super.currentStep;
  }

  @override
  set currentStep(int value) {
    _$currentStepAtom.reportWrite(value, super.currentStep, () {
      super.currentStep = value;
    });
  }

  late final _$completedAtom = Atom(
    name: '_OnboardingStore.completed',
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

  late final _$completeOnboardingAsyncAction = AsyncAction(
    '_OnboardingStore.completeOnboarding',
    context: context,
  );

  @override
  Future<void> completeOnboarding() {
    return _$completeOnboardingAsyncAction.run(
      () => super.completeOnboarding(),
    );
  }

  late final _$_OnboardingStoreActionController = ActionController(
    name: '_OnboardingStore',
    context: context,
  );

  @override
  void goTo(int step) {
    final _$actionInfo = _$_OnboardingStoreActionController.startAction(
      name: '_OnboardingStore.goTo',
    );
    try {
      return super.goTo(step);
    } finally {
      _$_OnboardingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void nextStep() {
    final _$actionInfo = _$_OnboardingStoreActionController.startAction(
      name: '_OnboardingStore.nextStep',
    );
    try {
      return super.nextStep();
    } finally {
      _$_OnboardingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void previousStep() {
    final _$actionInfo = _$_OnboardingStoreActionController.startAction(
      name: '_OnboardingStore.previousStep',
    );
    try {
      return super.previousStep();
    } finally {
      _$_OnboardingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void restore() {
    final _$actionInfo = _$_OnboardingStoreActionController.startAction(
      name: '_OnboardingStore.restore',
    );
    try {
      return super.restore();
    } finally {
      _$_OnboardingStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
currentStep: ${currentStep},
completed: ${completed},
isLastStep: ${isLastStep},
stepLabel: ${stepLabel},
progress: ${progress}
    ''';
  }
}
