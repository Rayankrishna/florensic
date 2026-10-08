import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../utils/app_clock.dart';

/// A photo the keeper just took or chose, with the location it was taken at
/// when that was available.
class Capture {
  const Capture({
    required this.file,
    required this.source,
    required this.capturedAt,
    this.lat,
    this.lon,
    this.accuracyM,
  });

  final File file;

  /// `camera` or `gallery` — the backend records which.
  final String source;
  final DateTime capturedAt;
  final double? lat;
  final double? lon;
  final double? accuracyM;

  String get path => file.path;

  Capture copyWith({double? lat, double? lon, double? accuracyM}) => Capture(
        file: file,
        source: source,
        capturedAt: capturedAt,
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
        accuracyM: accuracyM ?? this.accuracyM,
      );
}

/// Raised when the keeper has permanently refused a permission, so the app
/// must send them to Settings rather than ask again.
class PermissionPermanentlyDenied implements Exception {
  const PermissionPermanentlyDenied(this.permission);

  /// `camera`, `photos` or `location`.
  final String permission;

  @override
  String toString() => switch (permission) {
        'camera' => 'Camera access is off. Turn it on in Settings to take '
            'plant photos.',
        'photos' => 'Photo library access is off. Turn it on in Settings to '
            'choose a photo.',
        _ => 'Location access is off. Turn it on in Settings for '
            'weather-aware care.',
      };
}

/// Where the in-app viewfinder stands on camera access.
enum CameraAccess {
  granted,

  /// Refused this time — asking again can still show the system prompt.
  denied,

  /// Refused for good — only Settings can change it.
  blocked,
}

/// Camera, photo library and location, behind one interface so the stores do
/// not deal with three plugins.
class CaptureService {
  CaptureService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Long side capped and re-encoded so uploads stay inside the backend's
  /// 12 MB limit while keeping the short side well above the 480 px floor.
  static const double _maxEdge = 2048;
  static const int _quality = 88;

  /// Returns as soon as the picker closes, without a location, so the
  /// screen can show the photo at once; [located] adds the position after.
  Future<Capture?> takePhoto() => _pick(ImageSource.camera);

  Future<Capture?> pickFromGallery() => _pick(ImageSource.gallery);

  /// Camera access for the in-app viewfinder. With [prompt] false it only
  /// reads the current state, so coming back from Settings never re-opens
  /// the system dialog.
  Future<CameraAccess> cameraAccess({bool prompt = true}) async {
    final status = prompt
        ? await Permission.camera.request()
        : await Permission.camera.status;
    if (status.isGranted) return CameraAccess.granted;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return CameraAccess.blocked;
    }
    return CameraAccess.denied;
  }

  /// Wraps a frame the in-app viewfinder took. No location yet; [located]
  /// adds it before the upload.
  Future<Capture> fromViewfinder(File file) async =>
      Capture(file: file, source: 'camera', capturedAt: AppClock.now());

  /// The same capture with where it was taken, when the keeper allows that.
  /// Location is a nicety, never a blocker: weather-aware care is better
  /// with it, and the upload still succeeds without it.
  Future<Capture> located(Capture taken) async {
    final position = await _tryLocation();
    if (position == null) return taken;
    return taken.copyWith(
      lat: position.latitude,
      lon: position.longitude,
      accuracyM: position.accuracy,
    );
  }

  Future<Capture?> _pick(ImageSource source) async {
    await _ensureMediaPermission(source);

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: _maxEdge,
      maxHeight: _maxEdge,
      imageQuality: _quality,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (picked == null) return null; // The keeper backed out.

    return Capture(
      file: File(picked.path),
      source: source == ImageSource.camera ? 'camera' : 'gallery',
      capturedAt: AppClock.now(),
    );
  }

  /// iOS asks the picker itself for library access, so only the camera and
  /// Android's gallery need an explicit request.
  Future<void> _ensureMediaPermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status.isPermanentlyDenied || status.isRestricted) {
        throw const PermissionPermanentlyDenied('camera');
      }
      if (!status.isGranted) {
        throw const PermissionPermanentlyDenied('camera');
      }
      return;
    }
    if (!Platform.isAndroid) return;
    final photos = await Permission.photos.request();
    if (photos.isGranted || photos.isLimited) return;
    // Android 12 and below expose the library as storage.
    final storage = await Permission.storage.request();
    if (!storage.isGranted) {
      throw const PermissionPermanentlyDenied('photos');
    }
  }

  Future<Position?> _tryLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> openSettings() => openAppSettings();
}

/// Capture without a camera, for the test suite and the goldens.
///
/// It returns a synthetic capture whose file does not exist — every place
/// that renders a photo already falls back to the drawn artwork when the file
/// cannot be read, so the flow advances exactly as it does on a device.
class StubCaptureService extends CaptureService {
  StubCaptureService();

  @override
  Future<Capture?> takePhoto() async => _fake('camera');

  @override
  Future<Capture?> pickFromGallery() async => _fake('gallery');

  @override
  Future<Capture> located(Capture taken) async => taken;

  @override
  Future<CameraAccess> cameraAccess({bool prompt = true}) async =>
      CameraAccess.granted;

  @override
  Future<Capture> fromViewfinder(File file) async =>
      Capture(file: file, source: 'camera', capturedAt: AppClock.now());

  /// Returns immediately: the real shutter has its own latency, and an
  /// artificial one here only makes tests wait.
  Capture _fake(String source) => Capture(
        file: File(
          'stub-capture-${AppClock.now().microsecondsSinceEpoch}.jpg',
        ),
        source: source,
        capturedAt: AppClock.now(),
      );

  @override
  Future<bool> openSettings() async => true;
}
