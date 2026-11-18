import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/core/services_config.dart';
import '../../domain/core/token_store.dart';
import '../../locator.dart';

/// What a request for [url] has to carry: the bearer token for our own API,
/// nothing for a signed storage link, which must never see it.
Map<String, String>? _authHeaders(String url) {
  if (!url.startsWith(serverUrl)) return null;
  final token = locator.isRegistered<TokenStore>()
      ? locator<TokenStore>().current?.accessToken
      : null;
  if (token == null) return null;
  return {'Authorization': 'Bearer $token', ngrokSkipWarningHeader: 'true'};
}

/// An image cached by its address alone.
///
/// `NetworkImage` counts its headers in its cache key, and ours carry a
/// bearer token that changes every 15 minutes — so each refresh orphaned
/// every photo already downloaded and fetched it all again. This provider
/// reads the token only at the moment it fetches, so one copy of a photo
/// serves the whole session, and a picture already on screen resolves at
/// once anywhere else it is shown.
@immutable
class AuthNetworkImage extends ImageProvider<AuthNetworkImage> {
  const AuthNetworkImage(this.url);

  final String url;

  @override
  Future<AuthNetworkImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<AuthNetworkImage>(this);

  @override
  ImageStreamCompleter loadImage(
    AuthNetworkImage key,
    ImageDecoderCallback decode,
  ) {
    final inner = NetworkImage(key.url, headers: _authHeaders(key.url));
    final completer = inner.loadImage(inner, decode);
    // A failure — an expired token, mostly — must not stay cached under
    // this key, or the retry after a refresh would be served the same error.
    completer.addEphemeralErrorListener(
      (_, _) => scheduleMicrotask(
        () => PaintingBinding.instance.imageCache.evict(key),
      ),
    );
    return completer;
  }

  @override
  bool operator ==(Object other) =>
      other is AuthNetworkImage && other.url == url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => '${objectRuntimeType(this, 'AuthNetworkImage')}("$url")';
}

/// The provider [AuthImage] draws [url] with — the same cache entry. The
/// photo viewer reads a photo's true shape through it.
ImageProvider authImageProvider(String url) => AuthNetworkImage(url);

/// A photo served by the API.
///
/// The image links on a plant are routes, not public files: the server
/// streams the image only to its owner, so the request carries the bearer
/// token like every other call. The token goes only to our own API host —
/// production will hand out signed storage links in the same fields, and
/// those must never see it. [fallback] shows while the image loads and
/// whenever it cannot be shown. On a failure against the API the session is
/// refreshed once and the load retried — an expired access token is the
/// usual cause; a deleted photo stays on the fallback.
class AuthImage extends StatefulWidget {
  const AuthImage({
    super.key,
    required this.url,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  final String url;
  final Widget fallback;
  final BoxFit fit;
  final Alignment alignment;

  @override
  State<AuthImage> createState() => _AuthImageState();
}

class _AuthImageState extends State<AuthImage> {
  bool _retried = false;

  /// Bumped after a refresh so the image is requested again with the new
  /// token rather than served from the failed attempt.
  int _attempt = 0;

  @override
  void didUpdateWidget(AuthImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _retried = false;
  }

  /// True for a link on our API (`/v1/photos/{id}/{variant}`), which needs
  /// the token; false for a signed storage link, which must not get it.
  bool get _isApiUrl => widget.url.startsWith(serverUrl);

  Future<void> _retryAfterRefresh() async {
    final refreshed = await http?.refreshSession() ?? false;
    if (refreshed && mounted) setState(() => _attempt++);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.url.isEmpty) return widget.fallback;
    final token = locator<TokenStore>().current?.accessToken;
    if (_isApiUrl && token == null) return widget.fallback;
    return Image(
      image: AuthNetworkImage(widget.url),
      key: ValueKey('${widget.url}#$_attempt'),
      fit: widget.fit,
      alignment: widget.alignment,
      gaplessPlayback: true,
      // The artwork stays up until the first frame has decoded.
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
          frame == null && !wasSynchronouslyLoaded ? widget.fallback : child,
      errorBuilder: (context, error, stackTrace) {
        // Only an API link can be rescued by a fresh token.
        if (_isApiUrl && !_retried) {
          _retried = true;
          _retryAfterRefresh();
        }
        return widget.fallback;
      },
    );
  }
}

/// A photo when there is a link, the drawn artwork otherwise — the one-line
/// form for a card, tile or hero that has both a picture and a glyph.
///
/// [localPath] is a copy of the photo on this device (a plant just added
/// from a scan). It shows straight away, and stays up while [url] loads or
/// when it cannot be shown.
class PhotoOrArtwork extends StatelessWidget {
  const PhotoOrArtwork({
    super.key,
    required this.url,
    required this.artwork,
    this.localPath,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  /// `null` or empty draws [localPath], or [artwork] alone.
  final String? url;
  final Widget artwork;
  final String? localPath;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final local = localPath;
    final fallback = local == null || local.isEmpty
        ? artwork
        : Image.file(
            File(local),
            fit: fit,
            alignment: alignment,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => artwork,
          );
    final link = url;
    if (link == null || link.isEmpty) return fallback;
    return AuthImage(
        url: link, fallback: fallback, fit: fit, alignment: alignment);
  }
}
