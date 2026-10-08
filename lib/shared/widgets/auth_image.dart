import 'package:flutter/material.dart';

import '../../domain/core/services_config.dart';
import '../../domain/core/token_store.dart';
import '../../locator.dart';

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
    return Image.network(
      widget.url,
      key: ValueKey('${widget.url}#$_attempt'),
      headers: _isApiUrl ? {'Authorization': 'Bearer $token'} : null,
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
class PhotoOrArtwork extends StatelessWidget {
  const PhotoOrArtwork({
    super.key,
    required this.url,
    required this.artwork,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  /// `null` or empty draws [artwork] alone.
  final String? url;
  final Widget artwork;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final link = url;
    if (link == null || link.isEmpty) return artwork;
    return AuthImage(url: link, fallback: artwork, fit: fit, alignment: alignment);
  }
}
