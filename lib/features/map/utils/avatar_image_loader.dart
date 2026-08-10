import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart';

/// Loads and caches decoded avatar images for drawing directly onto map
/// marker canvases. `dart:ui.Canvas` can't consume `CachedNetworkImage` as a
/// widget - it needs a raw `ui.Image` - so this resolves one via the same
/// `CachedNetworkImageProvider` disk/memory cache `UserAvatar` already uses
/// (no duplicate network traffic).
abstract final class AvatarImageLoader {
  static final Map<String, ui.Image> _resolved = {};
  static final Map<String, Future<void>> _inFlight = {};

  /// Synchronous lookup - never triggers a network request. Null while
  /// loading, on failure, or when [url] is null/empty (callers fall back to
  /// the existing gradient+initials marker in all of these cases).
  static ui.Image? cached(String? url) {
    if (url == null || url.isEmpty) return null;
    return _resolved[url];
  }

  /// Fire-and-forget resolve of [url] into the cache. Safe to call
  /// repeatedly - dedupes concurrent loads and no-ops once resolved.
  /// Failures leave the URL unresolved permanently for this session (no
  /// retry loop); callers just keep getting the fallback rendering.
  static Future<void> prefetch(String? url) {
    if (url == null || url.isEmpty) return Future.value();
    if (_resolved.containsKey(url)) return Future.value();
    final existing = _inFlight[url];
    if (existing != null) return existing;

    final completer = Completer<void>();
    _inFlight[url] = completer.future;

    // Small target size - this is a ~50px marker, no need to decode a
    // full-resolution profile photo.
    final provider =
        ResizeImage(CachedNetworkImageProvider(url), width: 96, height: 96);
    final stream = provider.resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        _resolved[url] = info.image;
        stream.removeListener(listener);
        _inFlight.remove(url);
        completer.complete();
      },
      onError: (error, stackTrace) {
        stream.removeListener(listener);
        _inFlight.remove(url);
        completer.complete();
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  static void clearCache() {
    _resolved.clear();
    _inFlight.clear();
  }
}
