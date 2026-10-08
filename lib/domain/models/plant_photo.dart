import '../core/json.dart';

/// One photo in a plant's gallery (`GET /v1/plants/{id}/photos`), with its
/// image routes. Like a plant's `coverPhoto`, the routes stream the image
/// only to its owner, so they are loaded through `AuthImage`.
class PlantPhoto {
  const PlantPhoto({
    required this.id,
    required this.purpose,
    required this.framing,
    required this.source,
    required this.urls,
    required this.createdAt,
    this.capturedAt,
    this.width,
    this.height,
  });

  factory PlantPhoto.fromJson(Map<String, dynamic> json) => PlantPhoto(
        id: Json.str(json['id']),
        purpose: Json.str(json['purpose']),
        framing: Json.str(json['framing']),
        source: Json.str(json['source']),
        urls: PhotoUrls.fromJson(Json.map(json['urls'])),
        createdAt: Json.date(json['created_at']),
        capturedAt: Json.dateOrNull(json['captured_at']),
        width: Json.intOrNull(json['width']),
        height: Json.intOrNull(json['height']),
      );

  final String id;

  /// `identify` or `checkin`.
  final String purpose;
  final String framing;

  /// `camera` or `gallery`.
  final String source;
  final PhotoUrls urls;
  final DateTime createdAt;
  final DateTime? capturedAt;
  final int? width;
  final int? height;

  /// When it was taken, falling back to when it was uploaded.
  DateTime get takenAt => capturedAt ?? createdAt;
}

/// `thumb` for cards and grids, `working` for a detail view, `original` only
/// for a full-screen viewer.
class PhotoUrls {
  const PhotoUrls({
    required this.original,
    required this.working,
    required this.thumb,
  });

  factory PhotoUrls.fromJson(Map<String, dynamic> json) {
    final working = Json.str(json['working']);
    return PhotoUrls(
      original: Json.str(json['original'], working),
      working: working,
      thumb: Json.str(json['thumb'], working),
    );
  }

  final String original;
  final String working;
  final String thumb;
}
