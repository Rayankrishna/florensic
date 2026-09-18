import 'package:mobx/mobx.dart';

import '../key.dart';
import '../storage_manager.dart';

part 'onboarding_store.g.dart';

/// Number of steps in the introduction.
const int kOnboardingStepCount = 5;

class OnboardingStore = _OnboardingStore with _$OnboardingStore;

abstract class _OnboardingStore with Store {
  _OnboardingStore(this._storage);

  final StorageManager _storage;

  static const int stepCount = kOnboardingStepCount;

  @observable
  int currentStep = 0;

  @observable
  bool completed = false;

  @computed
  bool get isLastStep => currentStep == stepCount - 1;

  @computed
  String get stepLabel => 'STEP ${currentStep + 1} OF $stepCount';

  @computed
  double get progress => (currentStep + 1) / stepCount;

  @action
  void goTo(int step) => currentStep = step.clamp(0, stepCount - 1);

  @action
  void nextStep() {
    if (!isLastStep) currentStep++;
  }

  @action
  void previousStep() {
    if (currentStep > 0) currentStep--;
  }

  @action
  Future<void> completeOnboarding() async {
    completed = true;
    await _storage.setBool(StorageKeys.onboardingComplete, true);
  }

  @action
  void restore() {
    completed = _storage.getBool(StorageKeys.onboardingComplete);
  }
}
