import 'dart:async';
import 'dart:typed_data';

import 'package:melodix/core/service/music_service.dart';
import 'package:melodix/core/utils/lru_cache.dart';
import 'package:melodix/features/music_library/domain/repositories/artwork_repository.dart';

class ArtworkRepositoryImpl implements ArtworkRepository {
  ArtworkRepositoryImpl(this._musicService);

  final MusicService _musicService;

  /// Recently loaded artwork, keyed by "songId:size". Null values remember
  /// songs without artwork so they aren't queried again.
  final LruCache<String, Uint8List?> _cache = LruCache(capacity: 300);

  /// Loads in progress, so the same cover asked for twice at once (e.g. an
  /// album card and a song row) reads the device once.
  final Map<String, Future<Uint8List?>> _loading = {};

  @override
  FutureOr<Uint8List?> getArtwork(int songId, {int size = 200}) {
    final key = '$songId:$size';
    if (_cache.containsKey(key)) return _cache.get(key);
    // Block body on purpose: `remove` returns this very future, and
    // whenComplete would wait for a returned future, i.e. for itself.
    return _loading[key] ??= _load(key, songId, size).whenComplete(() {
      _loading.remove(key);
    });
  }

  @override
  ({Uint8List? bytes})? cachedArtwork(int songId, {int size = 200}) {
    final key = '$songId:$size';
    return _cache.containsKey(key) ? (bytes: _cache.get(key)) : null;
  }

  Future<Uint8List?> _load(String key, int songId, int size) async {
    final Uint8List? artwork;
    try {
      artwork = await _musicService.getArtwork(songId, size: size);
    } catch (_) {
      return null; // Not cached: e.g. no permission yet, retried later.
    }
    _cache.put(key, artwork);
    return artwork;
  }
}
