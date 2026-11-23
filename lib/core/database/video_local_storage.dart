import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/collections/video_collection.dart';
import 'package:melodix/core/models/local_video.dart';

/// Persists the device's video library and the user's data for each video.
abstract interface class VideoLocalStorage {
  /// Saves a fresh device scan: adds new videos, updates changed ones, removes
  /// videos that are gone, and keeps favorites / history / resume positions.
  Future<void> syncVideos(List<LocalVideo> scanned);

  /// All videos, newest first.
  Future<List<VideoCollection>> getAllVideos();

  /// Emits the full library (newest first) now and on every change.
  Stream<List<VideoCollection>> watchAllVideos();

  Future<List<VideoCollection>> searchVideos(String query);

  Future<List<VideoCollection>> getFavoriteVideos();

  Future<List<VideoCollection>> getRecentlyPlayed({int limit = 20});

  /// Videos started but not finished, most recent first.
  Future<List<VideoCollection>> getContinueWatching({int limit = 20});

  /// Flips the favorite flag and returns the new value.
  Future<bool> toggleFavorite(String videoId);

  /// Increments the play count and stamps the last-played time.
  Future<void> recordPlay(String videoId);

  /// Remembers where playback stopped. Positions near the end reset to 0 so
  /// finished videos don't show up in "continue watching".
  Future<void> savePlaybackPosition(String videoId, Duration position);
}

class VideoLocalStorageImpl implements VideoLocalStorage {
  VideoLocalStorageImpl(this._isar);

  final Isar _isar;

  /// Within this distance of the end, a video counts as finished.
  static const Duration _finishedThreshold = Duration(seconds: 10);

  IsarCollection<VideoCollection> get _videos => _isar.videoCollections;

  @override
  Future<void> syncVideos(List<LocalVideo> scanned) async {
    await _isar.writeTxn(() async {
      final existing = await _videos.where().findAll();
      final previousById = {for (final v in existing) v.videoId: v};
      final scannedIds = {for (final v in scanned) v.id};

      await _videos.putAll([
        for (final video in scanned)
          VideoCollection.fromLocalVideo(
            video,
            previous: previousById[video.id],
          ),
      ]);

      final removedIds = [
        for (final v in existing)
          if (!scannedIds.contains(v.videoId)) v.id,
      ];
      if (removedIds.isNotEmpty) await _videos.deleteAll(removedIds);
    });
  }

  @override
  Future<List<VideoCollection>> getAllVideos() =>
      _videos.where().sortByCreatedAtDesc().findAll();

  @override
  Stream<List<VideoCollection>> watchAllVideos() =>
      _videos.where().sortByCreatedAtDesc().watch(fireImmediately: true);

  @override
  Future<List<VideoCollection>> searchVideos(String query) {
    final q = query.trim();
    if (q.isEmpty) return getAllVideos();
    return _videos
        .filter()
        .titleContains(q, caseSensitive: false)
        .sortByCreatedAtDesc()
        .findAll();
  }

  @override
  Future<List<VideoCollection>> getFavoriteVideos() =>
      _videos.filter().isFavoriteEqualTo(true).sortByCreatedAtDesc().findAll();

  @override
  Future<List<VideoCollection>> getRecentlyPlayed({int limit = 20}) => _videos
      .filter()
      .lastPlayedAtIsNotNull()
      .sortByLastPlayedAtDesc()
      .limit(limit)
      .findAll();

  @override
  Future<List<VideoCollection>> getContinueWatching({int limit = 20}) => _videos
      .filter()
      .lastPositionMsGreaterThan(0)
      .sortByLastPlayedAtDesc()
      .limit(limit)
      .findAll();

  @override
  Future<bool> toggleFavorite(String videoId) {
    return _isar.writeTxn(() async {
      final video = await _videos.getByVideoId(videoId);
      if (video == null) return false;
      video.isFavorite = !video.isFavorite;
      await _videos.put(video);
      return video.isFavorite;
    });
  }

  @override
  Future<void> recordPlay(String videoId) {
    return _isar.writeTxn(() async {
      final video = await _videos.getByVideoId(videoId);
      if (video == null) return;
      video
        ..playCount += 1
        ..lastPlayedAt = DateTime.now();
      await _videos.put(video);
    });
  }

  @override
  Future<void> savePlaybackPosition(String videoId, Duration position) {
    return _isar.writeTxn(() async {
      final video = await _videos.getByVideoId(videoId);
      if (video == null) return;
      final finished = video.duration - position <= _finishedThreshold;
      video
        ..lastPositionMs = finished ? 0 : position.inMilliseconds
        ..lastPlayedAt = DateTime.now();
      await _videos.put(video);
    });
  }
}
