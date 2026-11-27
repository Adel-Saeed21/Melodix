import 'dart:async';
import 'dart:typed_data';

import 'package:melodix/features/video/data/datasources/video_service.dart';
import 'package:melodix/core/utils/lru_cache.dart';
import 'package:melodix/features/video/data/repositories/video_errors.dart';
import 'package:melodix/features/video/domain/repositories/video_media_repository.dart';

class VideoMediaRepositoryImpl implements VideoMediaRepository {
  VideoMediaRepositoryImpl(this._service, {int thumbnailCacheSize = 300})
    : _thumbnails = LruCache(capacity: thumbnailCacheSize);

  final VideoService _service;

  /// Recently loaded thumbnails, keyed by "videoId:size". Null values
  /// remember videos without one so they aren't asked for again.
  final LruCache<String, Uint8List?> _thumbnails;

  /// Loads in progress, so the same thumbnail asked for twice at once
  /// reads the device once.
  final Map<String, Future<Uint8List?>> _loading = {};

  @override
  FutureOr<Uint8List?> thumbnail(String videoId, {int size = 300}) {
    final key = '$videoId:$size';
    if (_thumbnails.containsKey(key)) return _thumbnails.get(key);
    // Block body on purpose: `remove` returns this very future, and
    // whenComplete would wait for a returned future, i.e. for itself.
    return _loading[key] ??= _loadThumbnail(key, videoId, size).whenComplete(
      () {
        _loading.remove(key);
      },
    );
  }

  @override
  ({Uint8List? bytes})? cachedThumbnail(String videoId, {int size = 300}) {
    final key = '$videoId:$size';
    return _thumbnails.containsKey(key) ? (bytes: _thumbnails.get(key)) : null;
  }

  Future<Uint8List?> _loadThumbnail(
    String key,
    String videoId,
    int size,
  ) async {
    final Uint8List? bytes;
    try {
      bytes = await _service.thumbnail(videoId, size: size);
    } catch (_) {
      return null; // Not cached: e.g. no permission yet, retried later.
    }
    _thumbnails.put(key, bytes);
    return bytes;
  }

  @override
  Future<Uri?> playbackUri(String videoId) async {
    try {
      return await _service.playbackUri(videoId);
    } catch (e, stack) {
      logVideoProblem('No playback URI for a video', e, stack);
      return null;
    }
  }
}
