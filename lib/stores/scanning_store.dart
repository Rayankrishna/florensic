import 'package:mobx/mobx.dart';

import '../domain/models/plant.dart';
import '../domain/repositories/identification_repository.dart';
import '../domain/repositories/mock/mock_api_client.dart';
import '../enum.dart';
import 'plant_collection_store.dart';
import 'permissions_store.dart';

part 'scanning_store.g.dart';

class ScanningStore = _ScanningStore with _$ScanningStore;

/// Plant identification.
///
/// Identification is not performed on device. The repository returns a
/// scripted match so the capture → result → add flow, and its offline and
/// no-match states, are fully exercised against mock responses.
abstract class _ScanningStore with Store {
  _ScanningStore(
    this._repository,
    this._collection,
    this._permissions,
    this._client,
  );

  final IdentificationRepository _repository;
  final PlantCollectionStore _collection;
  final PermissionsStore _permissions;
  final MockApiClient _client;

  @observable
  ScanStatus status = ScanStatus.idle;

  @observable
  ScanTarget target = ScanTarget.leaf;

  @observable
  bool torchOn = false;

  @observable
  IdentificationResult? result;

  @observable
  String? errorMessage;

  @observable
  bool isAdding = false;

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
  void toggleTorch() => torchOn = !torchOn;

  @action
  void resetScan() {
    status = ScanStatus.idle;
    result = null;
    errorMessage = null;
  }

  /// Test hooks so the designed error states are reachable from the UI.
  @action
  void simulateOffline(bool value) => _client.offline = value;

  @action
  void simulateNoMatch(bool value) => _repository.alwaysFail = value;

  @action
  Future<void> scanPlant() async {
    if (isScanning) return;
    status = ScanStatus.scanning;
    errorMessage = null;
    try {
      final match = await _repository.identify(framing: target.name);
      result = match;
      status = ScanStatus.matched;
    } on NoConfidentMatch catch (e) {
      errorMessage = e.toString();
      status = ScanStatus.noMatch;
    } catch (e) {
      errorMessage = e.toString();
      status = ScanStatus.offline;
    }
  }

  /// Picking an existing photo follows the same path as a capture.
  @action
  Future<void> selectImage() async {
    if (!photoLibraryEnabled) {
      errorMessage = 'Photo library access is off';
      status = ScanStatus.noMatch;
      return;
    }
    await scanPlant();
  }

  @action
  Future<Plant?> addToCollection({String? nickname}) async {
    final match = result;
    if (match == null || isAdding) return null;
    isAdding = true;
    try {
      return await _collection.addPlant(match.species, nickname: nickname);
    } finally {
      isAdding = false;
    }
  }
}
