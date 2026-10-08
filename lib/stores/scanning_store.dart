import 'dart:io';

import 'package:mobx/mobx.dart';

import '../domain/models/plant.dart';
import '../domain/repositories/identification_repository.dart';
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

  @observable
  bool isAdding = false;

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
    errorMessage = null;
    capture = null;
    needsSettings = false;
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

  @action
  Future<Plant?> addToCollection({String? nickname}) async {
    final match = result;
    if (match == null || isAdding) return null;
    isAdding = true;
    try {
      return await _collection.addPlant(match.species, nickname: nickname);
    } finally {
      runInAction(() => isAdding = false);
    }
  }
}
