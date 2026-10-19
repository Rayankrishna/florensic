import 'dart:io';

import 'package:mobx/mobx.dart';

import '../domain/models/plant.dart';
import '../domain/repositories/identification_repository.dart';
import '../domain/provider/species.provider.dart';
import '../domain/repositories/remote/remote_identification_repository.dart';
import '../enum.dart';
import '../utils/app_log.dart';
import '../interceptors/api_interceptor.dart';
import '../shared/services/capture_service.dart';
import 'plant_collection_store.dart';
import 'permissions_store.dart';

part 'scanning_store.g.dart';

class ScanningStore = _ScanningStore with _$ScanningStore;

/// Plant identification.
///
/// Identification is not performed on device. The repository returns a
/// scripted match so the capture → result → add flow, and its offline and
/// no-match states, come from the identification service.
abstract class _ScanningStore with Store {
  _ScanningStore(
    this._repository,
    this._collection,
    this._permissions,
    this._capture,
  );

  final IdentificationRepository _repository;
  final PlantCollectionStore _collection;
  final PermissionsStore _permissions;
  final CaptureService _capture;

  @observable
  ScanStatus status = ScanStatus.idle;

  @observable
  ScanTarget target = ScanTarget.leaf;

  @observable
  IdentificationResult? result;

  @observable
  String? errorMessage;

  /// The photo waiting to be identified, so the review UI can show it.
  @observable
  Capture? capture;

  /// True while the camera or picker is open.
  @observable
  bool isCapturing = false;

  /// Set when a permission was permanently refused — the sheet then offers
  /// Settings rather than another prompt.
  @observable
  bool needsSettings = false;

  /// The correction search: what was typed and the rows it brought back.
  @observable
  String suggestionQuery = '';

  @observable
  ObservableList<SpeciesSuggestion> suggestions =
      ObservableList<SpeciesSuggestion>();

  @observable
  bool isSuggesting = false;

  /// True while a tapped row is being resolved to a species.
  @observable
  bool isCorrecting = false;

  @observable
  String? correctionError;

  /// The match as the scan made it, kept while a correction stands so the
  /// keeper can go back to it.
  IdentificationResult? _uncorrected;

  @computed
  bool get isScanning => status == ScanStatus.scanning;

  @computed
  bool get hasMatch => status == ScanStatus.matched && result != null;

  @computed
  int get confidence => result?.confidence ?? 0;

  @computed
  bool get photoLibraryEnabled => _permissions.hasPhotoLibrary;

  @computed
  bool get showFailureSheet =>
      status == ScanStatus.noMatch || status == ScanStatus.offline;

  @computed
  String get failureTitle => status == ScanStatus.offline
      ? 'No internet connection'
      : "We couldn't place this one";

  @action
  void setTarget(ScanTarget value) => target = value;

  @action
  void resetScan() {
    status = ScanStatus.idle;
    result = null;
    _uncorrected = null;
    errorMessage = null;
    capture = null;
    needsSettings = false;
    clearSuggestions();
  }

  @action
  void clearSuggestions() {
    suggestionQuery = '';
    suggestions.clear();
    correctionError = null;
  }

  /// Sequence number so a slow answer to an earlier query cannot land over
  /// the rows for the current one.
  int _suggestSeq = 0;

  /// Typeahead for the correction search; the screen debounces the typing.
  @action
  Future<void> suggestSpecies(String query) async {
    final q = query.trim();
    suggestionQuery = q;
    final seq = ++_suggestSeq;
    if (q.length < 2) {
      suggestions.clear();
      isSuggesting = false;
      return;
    }
    isSuggesting = true;
    try {
      final rows = await _repository.suggestSpecies(q);
      if (seq != _suggestSeq) return;
      runInAction(() => suggestions = ObservableList<SpeciesSuggestion>.of(rows));
    } catch (e) {
      AppLog.w('species suggest failed: $e', name: 'scan');
    } finally {
      if (seq == _suggestSeq) runInAction(() => isSuggesting = false);
    }
  }

  /// The keeper knows better: resolves the tapped row and keeps the plant as
  /// that species. The add then sends `species_id`, which is the correction.
  @action
  Future<bool> correctSpecies(SpeciesSuggestion pick) async {
    final match = result;
    if (match == null || isCorrecting) return false;
    isCorrecting = true;
    correctionError = null;
    try {
      final species = await _repository.resolveSpecies(pick);
      runInAction(() {
        _uncorrected ??= match;
        result = match.correctedTo(species);
      });
      return true;
    } on ApiException catch (e) {
      AppLog.w('species correction failed: ${e.code}', name: 'scan');
      runInAction(() => correctionError = e.message);
      return false;
    } catch (e, stack) {
      AppLog.e('species correction failed',
          name: 'scan', error: e, stackTrace: stack);
      runInAction(() => correctionError = e.toString());
      return false;
    } finally {
      runInAction(() => isCorrecting = false);
    }
  }

  /// A runner-up the keeper agrees with. It is already a catalogue species,
  /// so nothing needs resolving; an unlisted one cannot be picked.
  @action
  void useAlternative(IdentificationAlternative alt) {
    final match = result;
    if (match == null || !alt.isListed) return;
    _uncorrected ??= match;
    result = match.correctedTo(alt.species);
  }

  /// Back to what the scan said.
  @action
  void revertCorrection() {
    final original = _uncorrected;
    if (original == null) return;
    result = original;
    _uncorrected = null;
  }

  /// Opens the system camera, then identifies whatever came back — the
  /// fallback for when the in-app viewfinder has no camera to show.
  @action
  Future<void> scanPlant() async {
    if (isScanning || isCapturing) return;
    final taken = await _takePhoto(fromCamera: true);
    if (taken == null) return;
    await _identify();
  }

  /// Identifies a frame the in-app viewfinder just took.
  @action
  Future<void> identifyPhoto(File file) async {
    if (isScanning || isCapturing) return;
    isCapturing = true;
    errorMessage = null;
    needsSettings = false;
    try {
      final taken =
          await _capture.located(await _capture.fromViewfinder(file));
      runInAction(() {
        capture = taken;
        _attachCapture(taken);
      });
    } finally {
      runInAction(() => isCapturing = false);
    }
    await _identify();
  }

  /// Picking an existing photo follows the same path as a capture.
  @action
  Future<void> selectImage() async {
    if (isScanning || isCapturing) return;
    final taken = await _takePhoto(fromCamera: false);
    if (taken == null) return;
    await _identify();
  }

  @action
  Future<Capture?> _takePhoto({required bool fromCamera}) async {
    isCapturing = true;
    errorMessage = null;
    needsSettings = false;
    try {
      final picked = fromCamera
          ? await _capture.takePhoto()
          : await _capture.pickFromGallery();
      if (picked == null) return null; // Cancelled — stay on the viewfinder.
      // On screen at once — held and blurred — while the location follows.
      runInAction(() => capture = picked);
      final taken = await _capture.located(picked);
      runInAction(() {
        capture = taken;
        _attachCapture(taken);
      });
      return taken;
    } on PermissionPermanentlyDenied catch (e) {
      AppLog.w('capture blocked: $e', name: 'scan');
      runInAction(() {
        errorMessage = e.toString();
        needsSettings = true;
        status = ScanStatus.noMatch;
      });
      return null;
    } catch (e, stack) {
      AppLog.e('capture failed', name: 'scan', error: e, stackTrace: stack);
      runInAction(() {
        errorMessage = e.toString();
        status = ScanStatus.noMatch;
      });
      return null;
    } finally {
      runInAction(() => isCapturing = false);
    }
  }

  /// Hands the frame to the repository, which uploads it.
  void _attachCapture(Capture taken) {
    final repository = _repository;
    if (repository is RemoteIdentificationRepository) {
      repository.pendingCapture = taken;
    }
  }

  @action
  Future<void> _identify() async {
    status = ScanStatus.scanning;
    errorMessage = null;

    IdentificationResult match;
    try {
      match = await _repository.identify(framing: target.name);
    } on NoConfidentMatch catch (e) {
      AppLog.i('no confident match', name: 'scan');
      runInAction(() {
        errorMessage = e.toString();
        status = ScanStatus.noMatch;
      });
      return;
    } on ApiException catch (e) {
      AppLog.e('identification failed', name: 'scan', error: e);
      runInAction(() {
        errorMessage = e.message;
        status = e.isOffline ? ScanStatus.offline : ScanStatus.noMatch;
      });
      return;
    } catch (e, stack) {
      AppLog.e('identification failed',
          name: 'scan', error: e, stackTrace: stack);
      runInAction(() {
        errorMessage = e.toString();
        status = ScanStatus.offline;
      });
      return;
    }

    AppLog.i('matched ${match.species.commonName} at ${match.confidence}%',
        name: 'scan');
    runInAction(() {
      result = match;
      status = ScanStatus.matched;
    });
  }

  /// Sends the keeper to the OS settings page for a refused permission.
  @action
  Future<void> openSettings() => _capture.openSettings();

  /// Keeps the plant without waiting on the server: the draft goes into the
  /// collection at once and the save carries on behind it (see
  /// [PlantCollectionStore.addPlant]). The photo that found the plant is the
  /// one required field; the species goes only when the keeper corrected
  /// the identification. Null when there is nothing to keep.
  @action
  Plant? addToCollection({String? nickname}) {
    final match = result;
    final photoId = match?.photoId;
    if (match == null || photoId == null) return null;
    return _collection.addPlant(
      match.species,
      photoId: photoId,
      speciesId:
          match.corrected && match.species.isListed ? match.species.id : null,
      nickname: nickname,
      localPhotoPath: capture?.path,
      scanHealth: match.initialHealth,
    );
  }
}
