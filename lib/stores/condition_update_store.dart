import 'dart:io';

import 'package:mobx/mobx.dart';

import '../domain/models/plant.dart';
import '../domain/provider/photos.provider.dart';
import '../domain/repositories/plant_repository.dart';
import '../domain/repositories/remote/remote_plant_repository.dart';
import '../enum.dart';
import '../utils/app_log.dart';
import '../interceptors/api_interceptor.dart';
import '../shared/services/capture_service.dart';
import 'plant_collection_store.dart';

part 'condition_update_store.g.dart';

class ConditionUpdateStore = _ConditionUpdateStore with _$ConditionUpdateStore;

/// The three-step condition update: capture → review → details.
abstract class _ConditionUpdateStore with Store {
  _ConditionUpdateStore(this._repository, this._collection, this._capture,
      this._photos);

  final PlantRepository _repository;
  final PlantCollectionStore _collection;
  final CaptureService _capture;
  final PhotosProvider _photos;

  static const int stepCount = 3;

  @observable
  Plant? plant;

  @observable
  int step = 0;

  @observable
  bool isCapturing = false;

  @observable
  bool hasPhoto = false;

  /// The photo for this check-in, shown on the review step.
  @observable
  Capture? photo;

  /// Set when a permission was permanently refused.
  @observable
  bool needsSettings = false;

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

  /// Null on a plant's first scored check-in — there was nothing to move
  /// from — so the chip is only shown when it is set.
  @observable
  int? scoreDelta;

  /// The photo was too poor to read, so the number is held lightly.
  @observable
  bool provisional = false;

  /// What the model made of the photo, when it ran.
  @observable
  ConditionVerdict? modelVerdict;

  @observable
  bool verdictDisagreement = false;

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
    photo = null;
    needsSettings = false;
    capturedAt = null;
    verdict = null;
    observations.clear();
    note = '';
    newScore = null;
    scoreDelta = null;
    provisional = false;
    modelVerdict = null;
    verdictDisagreement = false;
    errorMessage = null;
  }

  /// Opens the camera and, on the real backend, uploads the frame so the
  /// analyser has it ready when the update is saved (§3.4).
  @action
  Future<void> capture({bool fromCamera = true}) async {
    if (isCapturing) return;
    isCapturing = true;
    errorMessage = null;
    needsSettings = false;
    try {
      final taken = fromCamera
          ? await _capture.takePhoto()
          : await _capture.pickFromGallery();
      if (taken == null) return; // Cancelled — stay on the camera step.
      await _accept(taken);
    } on PermissionPermanentlyDenied catch (e) {
      AppLog.w('capture blocked: $e', name: 'checkin');
      runInAction(() {
        errorMessage = e.toString();
        needsSettings = true;
        photo = null;
      });
    } on ApiException catch (e) {
      AppLog.e('uploading the check-in photo failed',
          name: 'checkin', error: e);
      // Not kept: nothing stays held on the viewfinder.
      runInAction(() {
        errorMessage = e.message;
        photo = null;
      });
    } catch (e, stack) {
      AppLog.e('capture failed', name: 'checkin', error: e, stackTrace: stack);
      runInAction(() {
        errorMessage = e.toString();
        photo = null;
      });
    } finally {
      runInAction(() => isCapturing = false);
    }
  }

  /// A frame from the in-app viewfinder — the same camera the identify
  /// screen uses. False when it could not be kept, so the preview should
  /// resume for another try.
  @action
  Future<bool> captureFromViewfinder(File file) async {
    if (isCapturing) return false;
    isCapturing = true;
    errorMessage = null;
    needsSettings = false;
    try {
      await _accept(await _capture.fromViewfinder(file));
      return true;
    } on ApiException catch (e) {
      AppLog.e('uploading the check-in photo failed',
          name: 'checkin', error: e);
      runInAction(() {
        errorMessage = e.message;
        photo = null;
      });
      return false;
    } catch (e, stack) {
      AppLog.e('keeping the frame failed',
          name: 'checkin', error: e, stackTrace: stack);
      runInAction(() {
        errorMessage = e.toString();
        photo = null;
      });
      return false;
    } finally {
      runInAction(() => isCapturing = false);
    }
  }

  /// Keeps a capture, uploads it, and moves on to the review step.
  Future<void> _accept(Capture picked) async {
    // On screen at once — held and blurred — while the location follows.
    runInAction(() {
      photo = picked;
      capturedAt = picked.capturedAt;
    });
    final taken = await _capture.located(picked);
    runInAction(() => photo = taken);
    await _uploadIfRemote(taken);
    runInAction(() {
      hasPhoto = true;
      step = 1;
    });
  }

  /// A check-in photo is uploaded up front; the job only runs once the
  /// verdict is submitted.
  Future<void> _uploadIfRemote(Capture taken) async {
    final repository = _repository;
    if (repository is! RemotePlantRepository) return;
    final queued = await _photos.upload(
      filePath: taken.path,
      purpose: PhotoPurpose.checkin,
      plantId: plant!.id,
      framing: 'whole_plant',
      source: taken.source,
      lat: taken.lat,
      lon: taken.lon,
      locationAccuracyM: taken.accuracyM,
      capturedAt: taken.capturedAt,
    );
    repository.pendingCheckInPhotoId = queued.photoId;
  }

  /// Sends the keeper to the OS settings page for a refused permission.
  @action
  Future<void> openSettings() => _capture.openSettings();

  @action
  void retake() {
    hasPhoto = false;
    photo = null;
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

    CheckInResult result;
    try {
      result = await _repository.submitConditionUpdate(
        p.id,
        verdict: v,
        observations: observations.toList(),
        note: note,
      );
    } on ApiException catch (e) {
      AppLog.e('saving the check-in failed', name: 'checkin', error: e);
      runInAction(() {
        errorMessage = e.message;
        isSaving = false;
      });
      return false;
    } catch (e, stack) {
      AppLog.e('saving the check-in failed',
          name: 'checkin', error: e, stackTrace: stack);
      runInAction(() {
        errorMessage = e.toString();
        isSaving = false;
      });
      return false;
    }

    final updated = result.plant;
    final update = result.update;
    AppLog.i('check-in saved for ${updated.nickname}', name: 'checkin');
    runInAction(() {
      plant = updated;
      _collection.replacePlant(updated);
      // The score is the server's; nothing here does arithmetic on it.
      newScore = updated.healthScore;
      scoreDelta = update?.scoreDelta;
      provisional = update?.provisional ?? false;
      modelVerdict = update?.modelVerdict;
      verdictDisagreement = update?.verdictDisagreement ?? false;
      nextCheckIn = result.nextCheckIn ?? updated.schedule.checkInWindowOpens;
      isSaving = false;
    });
    // The check-in is what answers today's condition task; the list just
    // needs to catch up with the server.
    await _collection.refreshTodaysCare();
    return true;
  }

  static String _shortDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}
