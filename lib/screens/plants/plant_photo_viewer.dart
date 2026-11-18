import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/models/plant.dart';
import '../../domain/models/plant_photo.dart';
import '../../key.dart';
import '../../shared/widgets/auth_image.dart';
import '../../shared/widgets/photo_viewer.dart';
import '../../shared/widgets/plant_artwork.dart';
import '../../theme.dart';
import '../../utils/app_clock.dart';
import '../../utils/date_format.dart';
import 'plant_detail_sections.dart';

/// A plant's photos for the full-screen viewer, newest first.
///
/// [fromCard] opens on the cover photo and flies it out of the big card at
/// the top of the plant page; otherwise [index] is the history thumbnail
/// that was tapped. Null when there is nothing to show.
PhotoViewerArgs? plantPhotoViewerArgs(
  Plant plant,
  List<PlantPhoto> photos, {
  required bool fromCard,
  int index = 0,
}) {
  final cover = plant.coverPhoto;
  final local = plant.localPhotoPath;

  // The innermost layer: the copy on this device when the plant was just
  // added from a scan, else the drawing.
  Widget base(BoxFit fit) => local != null && local.isNotEmpty
      ? Image.file(
          File(local),
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => _artwork(plant),
        )
      : _artwork(plant);

  final items = <ViewerPhoto>[
    for (final p in photos)
      _fromPhoto(
        plant,
        p,
        base,
        card: fromCard && p.id == cover?.photoId ? cover : null,
      ),
  ];

  var initial = index;
  if (fromCard) {
    initial = cover == null
        ? -1
        : photos.indexWhere((p) => p.id == cover.photoId);
    // The gallery has not loaded, or does not list the cover yet, or the
    // plant is still being saved: put the card's own picture in front.
    if (initial < 0) {
      final front = cover != null
          ? _fromCover(plant, cover, base)
          : local != null && local.isNotEmpty
              ? ViewerPhoto(
                  heroTag: AppKeys.plantHero(plant.id),
                  image: base,
                  title: 'Just added',
                  originRadius: AppRadius.card,
                  probe: FileImage(File(local)),
                )
              : null;
      if (front != null) items.insert(0, front);
      initial = 0;
    }
  }

  if (items.isEmpty) return null;
  // The spots on screen behind the viewer that a photo can fly back into:
  // the card when it was tapped, else the strip — its thumbnails and the
  // "+N" tile, which holds the first photo it hides.
  // Mirrors ConditionHistoryStrip: the first few photos as thumbnails,
  // then a tile for the next one when the plant has more than that.
  final shown = photos.length.clamp(0, ConditionHistoryStrip.visible);
  final tile = plant.photoCount > shown && photos.length > shown;
  final partners = fromCard
      ? <Object>{AppKeys.plantHero(plant.id)}
      : <Object>{
          for (final p in photos.take(shown + (tile ? 1 : 0)))
            AppKeys.photoHero(p.id),
        };
  return PhotoViewerArgs(
    photos: items,
    initialIndex: initial.clamp(0, items.length - 1),
    partnerTags: partners,
  );
}

ViewerPhoto _fromPhoto(
  Plant plant,
  PlantPhoto photo,
  Widget Function(BoxFit fit) base, {
  CoverPhoto? card,
}) {
  final w = photo.width;
  final h = photo.height;
  final onCard = card != null;
  return ViewerPhoto(
    // The cover keeps the card's tag so it flies back into the card; every
    // other photo pairs with its own thumbnail in the history strip.
    heroTag: onCard ? AppKeys.plantHero(plant.id) : AppKeys.photoHero(photo.id),
    // Opened from the card, the card's own copy goes in the stack: it is
    // already decoded, so the flight carries the real photo even where the
    // gallery's links differ from the card's (signed links in production).
    image: (fit) => _layers(
      [
        photo.urls.original,
        photo.urls.working,
        ?card?.working,
        photo.urls.thumb,
        ?card?.thumb,
      ],
      fit,
      base,
    ),
    title: _taken(photo.takenAt),
    subtitle: switch (photo.purpose) {
      'identify' => 'First scan',
      'checkin' => 'Check-in',
      _ => null,
    },
    aspectRatio: w != null && h != null && w > 0 && h > 0 ? w / h : null,
    probe: authImageProvider(card?.working ?? photo.urls.working),
    originRadius: onCard ? AppRadius.card : AppRadius.tile,
  );
}

ViewerPhoto _fromCover(
  Plant plant,
  CoverPhoto cover,
  Widget Function(BoxFit fit) base,
) {
  return ViewerPhoto(
    heroTag: AppKeys.plantHero(plant.id),
    image: (fit) => _layers([cover.working, cover.thumb], fit, base),
    title: cover.capturedAt == null ? null : _taken(cover.capturedAt!),
    // The card already shows this copy, so its size comes straight from
    // the image cache.
    probe: authImageProvider(cover.working),
    originRadius: AppRadius.card,
  );
}

/// The sharpest copy over the smaller ones: whatever is already on the
/// device shows at once, and the full-size photo replaces it when it lands.
Widget _layers(
  List<String> urls,
  BoxFit fit,
  Widget Function(BoxFit fit) base,
) {
  var image = base(fit);
  final seen = <String>{};
  for (final url in urls.reversed) {
    if (url.isEmpty || !seen.add(url)) continue;
    image = AuthImage(url: url, fallback: image, fit: fit);
  }
  return image;
}

Widget _artwork(Plant plant) => PlantArtwork(
      glyph: plant.species.glyph,
      ground: plant.species.ground,
      inset: 0.08,
    );

String _taken(DateTime at) {
  final local = at.toLocal();
  final year = local.year == AppClock.now().year ? '' : ' ${local.year}';
  return 'Taken ${AppDate.dayMonth(local)}$year';
}
