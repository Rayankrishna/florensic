import 'package:mobx/mobx.dart';

import '../domain/models/plant.dart';
import '../domain/repositories/plant_repository.dart';
import '../enum.dart';
import 'plant_collection_store.dart';
import '../utils/app_clock.dart';

part 'condition_update_store.g.dart';

class ConditionUpdateStore = _ConditionUpdateStore with _$ConditionUpdateStore;

/// The three-step condition update: capture → review → details.
abstract class _ConditionUpdateStore with Store {
  _ConditionUpdateStore(this._repository, this._collection);

  final PlantRepository _repository;
  final PlantCollectionStore _collection;

  static const int stepCount = 3;

  @observable
  Plant? plant;

  @observable
  int step = 0;

  @observable
  bool isCapturing = false;

  @observable
  bool hasPhoto = false;

  @observable
  DateTime? capturedAt;

  @observable
  ConditionVerdict? verdict;

  @observable
  ObservableList<String> observations = ObservableList<String>();

  @observable
  String note = '';

  @observable
  bool isSaving = false;

  @observable
  String? errorMessage;

  /// Populated once the update is saved, for the confirmation screen.
  @observable
  int? newScore;

  @observable
  int scoreDelta = 0;

  @observable
  DateTime? nextCheckIn;

  @computed
  bool get canContinueFromReview => hasPhoto;

  @computed
  bool get canSave => verdict != null && !isSaving;

  @computed
  String get stepTitle => switch (step) {
        0 => 'Update plant condition',
        1 => 'Review photo',
        _ => 'Condition details',
      };

  /// Framing feedback on the review step. A real build would run this on the
  /// captured frame; here it is fixed copy so the step can be exercised.
  @computed
  String get framingNote =>
      'Good light and framing. The lower leaves are slightly cut off — fine, '
      'but try to include the pot next time.';

  @computed
  String get comparedWith {
    final last = plant?.updates.isNotEmpty == true ? plant!.updates.last : null;
    if (last == null) return 'First update';
    return '${_shortDate(last.takenAt)} update';
  }

  @computed
  String get visibleChange => plant?.updates.isEmpty == true
      ? 'Baseline photo'
      : '1 new leaf';

  @action
  void start(Plant value) {
    plant = value;
    step = 0;
    hasPhoto = false;
    capturedAt = null;
    verdict = null;
    observations.clear();
    note = '';
    newScore = null;
    scoreDelta = 0;
    errorMessage = null;
  }

  @action
  Future<void> capture() async {
    if (isCapturing) return;
    isCapturing = true;
    // Stands in for the camera shutter + file write.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    hasPhoto = true;
    capturedAt = AppClock.now();
    isCapturing = false;
    step = 1;
  }

  @action
  void retake() {
    hasPhoto = false;
    capturedAt = null;
    step = 0;
  }

  @action
  void next() {
    if (step < stepCount - 1) step++;
  }

  @action
  void back() {
    if (step > 0) step--;
  }

  @action
  void setVerdict(ConditionVerdict value) => verdict = value;

  @action
  void toggleObservation(String value) {
    if (observations.contains(value)) {
      observations.remove(value);
    } else {
      observations.add(value);
    }
  }

  @action
  void setNote(String value) => note = value;

  @action
  Future<bool> save() async {
    final p = plant;
    final v = verdict;
    if (p == null || v == null) return false;
    isSaving = true;
    errorMessage = null;
    try {
      final before = p.healthScore ?? 70;
      final updated = await _repository.submitConditionUpdate(
        p.id,
        verdict: v,
        observations: observations.toList(),
        note: note,
      );
      plant = updated;
      _collection.replacePlant(updated);
      newScore = updated.healthScore;
      scoreDelta = (updated.healthScore ?? before) - before;
      nextCheckIn = updated.schedule.checkInWindowOpens;
      _collection.completeTask('task-cond-${p.id}');
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSaving = false;
    }
  }

  static String _shortDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}
