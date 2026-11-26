import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/widgets/media_image/media_image_placeholder.dart';

/// A media item's picture (a song's cover, a video's thumbnail) loaded from
/// the device, with a themed placeholder while it loads or when there's
/// none. Built for long lists:
///
/// * a picture already in memory ([cached]) shows in the very first frame
///   (no placeholder flash when scrolling back);
/// * during a fast fling, pictures not in memory aren't asked for: rows
///   fly past in a frame or two, and each ask reads a file and decodes a
///   picture. A row still on screen once the scroll slows down asks then;
///   one that scrolled away never does;
/// * while a new item's picture loads, the placeholder shows, never the
///   previous item's picture.
class MediaImage extends StatefulWidget {
  const MediaImage({
    super.key,
    required this.mediaKey,
    required this.width,
    required this.height,
    required this.load,
    required this.cached,
    required this.borderRadius,
    required this.placeholderIcon,
  });

  /// Which item this is (e.g. the song or video id): the picture reloads
  /// when it changes.
  final Object mediaKey;

  /// Logical size.
  final double width;
  final double height;

  /// Loads the picture at about [pixels] px: synchronously if cached.
  final FutureOr<Uint8List?> Function(int pixels) load;

  /// The picture if it's in memory already, without loading: null when not
  /// cached; a record (whose bytes may be null: no picture) when it is.
  final ({Uint8List? bytes})? Function(int pixels) cached;

  final BorderRadius borderRadius;
  final IconData placeholderIcon;

  @override
  State<MediaImage> createState() => _MediaImageState();
}

class _MediaImageState extends State<MediaImage> {
  /// The picture of [_loadedFor]; null while loading or when it has none.
  Uint8List? _bytes;
  Object? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadIfNeeded();
  }

  @override
  void didUpdateWidget(MediaImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaKey != widget.mediaKey) _loadIfNeeded();
  }

  void _loadIfNeeded() {
    final key = widget.mediaKey;
    if (_loadedFor == key) return;
    _loadedFor = key;
    // Enough pixels for a sharp picture on this screen.
    final longest = widget.width > widget.height ? widget.width : widget.height;
    final pixels = (longest * MediaQuery.devicePixelRatioOf(context))
        .round()
        .clamp(64, 1024);

    if (Scrollable.recommendDeferredLoadingForContext(context)) {
      final cached = widget.cached(pixels);
      if (cached != null) {
        _bytes = cached.bytes;
        return;
      }
      _bytes = null;
      _loadWhenSettled(key, pixels);
      return;
    }
    _bytes = _load(key, pixels);
  }

  /// Checks again each frame until scrolling is slow enough to load.
  void _loadWhenSettled(Object key, int pixels) {
    SchedulerBinding.instance
      ..scheduleFrameCallback((_) {
        scheduleMicrotask(() {
          // Scrolled away (or reused for another item) meanwhile: nothing.
          if (!mounted || _loadedFor != key) return;
          if (Scrollable.recommendDeferredLoadingForContext(context)) {
            _loadWhenSettled(key, pixels);
            return;
          }
          final bytes = _load(key, pixels);
          if (bytes != null) setState(() => _bytes = bytes);
        });
      })
      ..ensureVisualUpdate();
  }

  /// Asks for the picture: returns it now if it's cached; otherwise shows
  /// it when it arrives (unless this widget moved on to another item).
  Uint8List? _load(Object key, int pixels) {
    final picture = widget.load(pixels);
    if (picture is! Future<Uint8List?>) return picture;
    picture.then((bytes) {
      if (mounted && _loadedFor == key && bytes != null) {
        setState(() => _bytes = bytes);
      }
    }, onError: (Object _) {});
    // Placeholder until then (never the previous item's picture).
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: bytes == null || bytes.isEmpty
            ? MediaImagePlaceholder(icon: widget.placeholderIcon)
            : Image.memory(
                bytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) =>
                    MediaImagePlaceholder(icon: widget.placeholderIcon),
              ),
      ),
    );
  }
}
