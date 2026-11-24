import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/collections/library_metadata_collection.dart';
import 'package:melodix/core/database/collections/video_collection.dart';
import 'package:melodix/core/database/collections/video_progress_collection.dart';
import 'package:melodix/core/errors/exceptions.dart';
import 'package:melodix/core/models/local_video.dart';

/// What a video sync changed.
class VideoSyncResult {
  const VideoSyncResult({
    required this.added,
    required this.updated,
    required this.removed,
    required this.total,
  });

  final int added;
  final int updated;
  final int removed;

  /// Videos in the library after the sync.
  final int total;

  bool get hasChanges => added > 0 || updated > 0 || removed > 0;
}

/// Persists the device's video library, favourites and watch progress.
abstract interface class VideoLocalStorage {
  /// Saves a fresh device scan in one transaction: adds new videos,
  /// rewrites only the ones whose details changed, removes the ones that
  /// are gone (with their progress), and keeps favourites and progress.
  ///
  /// Data safety: an empty scan never wipes a non-empty library unless
  /// [confirmedEmpty] (the device itself counted 0 videos); it throws
  /// [MediaQueryException] instead and changes nothing.
  ///
  /// [checkpoint] (the device's fingerprint taken before the scan) is saved
  /// with the videos, in the same transaction.
  ///
  /// [keepMissing]: the scan saw only part of the device (partial access),
  /// so videos it didn't see are kept, not removed.
  Future<VideoSyncResult> syncVideos(
    List<LocalVideo> scanned, {
    bool confirmedEmpty = false,
    String? checkpoint,
    bool keepMissing = false,
  });

  /// The device's fingerprint at the last full sync; null if none yet.
  Future<String?> videoCheckpoint();

  /// Notes a sync that found nothing changed (no scan, nothing written).
  Future<void> markVideosCheckedUnchanged();

  /// How many videos the library has.
  Future<int> countVideos();

  /// All videos, newest first.
  Future<List<VideoCollection>> getAllVideos();

  /// Emits the full library (newest first) now and whenever a video is
  /// added, changed, removed or (un)favourited. Never for watch progress.
  Stream<List<VideoCollection>> watchAllVideos();

  /// The favourite videos (newest first), now and on every change.
  Stream<List<VideoCollection>> watchFavoriteVideos();

  /// Flips the favorite flag and returns the new value.
  Future<bool> toggleFavorite(String videoId);

  /// Sets the favourite flag of all [videoIds] at once.
  Future<void> setFavorites(List<String> videoIds, {required bool favorite});

  /// Forgets videos deleted from the device (with their progress).
  Future<void> removeVideos(List<String> videoIds);

  /// Every video's progress (only videos ever played have one), now and on
  /// every change.
  Stream<List<VideoProgressCollection>> watchProgress();

  /// One video's progress; null if it was never played.
  Future<VideoProgressCollection?> getProgress(String videoId);

  /// Increments the play count and stamps the last-played time.
  Future<void> recordPlay(String videoId);

  /// Remembers where playback stopped (as given: deciding that a video was
  /// finished is the caller's rule) and stamps the time.
  Future<void> savePlaybackPosition(String videoId, Duration position);
}

class VideoLocalStorageImpl implements VideoLocalStorage {
  VideoLocalStorageImpl(this._isar);

  final Isar _isar;

  IsarCollection<VideoCollection> get _videos => _isar.videoCollections;
  IsarCollection<LibraryMetadataCollection> get _metadata =>
      _isar.libraryMetadataCollections;
  IsarCollection<VideoProgressCollection> get _progress =>
      _isar.videoProgressCollections;

  @override
  Future<VideoSyncResult> syncVideos(
    List<LocalVideo> scanned, {
    bool confirmedEmpty = false,
    String? checkpoint,
    bool keepMissing = false,
  }) {
    return _isar.writeTxn(() async {
      final existing = await _videos.where().findAll();
      if (scanned.isEmpty && existing.isNotEmpty && !confirmedEmpty) {
        throw const MediaQueryException(
          'Scan found no videos; not confirmed, library kept',
        );
      }
      final previousById = {for (final v in existing) v.videoId: v};
      final scannedIds = {for (final v in scanned) v.id};

      var added = 0;
      final changed = <VideoCollection>[];
      for (final video in scanned) {
        final previous = previousById[video.id];
        if (previous == null) {
          added++;
        } else if (previous.hasSameScanAs(video)) {
          continue; // unchanged: not rewritten
        }
        changed.add(VideoCollection.fromLocalVideo(video, previous: previous));
      }
      if (changed.isNotEmpty) await _videos.putAll(changed);

      final removed = [
        if (!keepMissing)
          for (final v in existing)
            if (!scannedIds.contains(v.videoId)) v,
      ];
      if (removed.isNotEmpty) {
        await _videos.deleteAll([for (final v in removed) v.id]);
        // Same ids: a progress row's id is the hash of its video id too.
        await _progress.deleteAll([for (final v in removed) v.id]);
      }
      final metadata =
          await _metadata.get(LibraryMetadataCollection.singletonId) ??
          LibraryMetadataCollection();
      await _metadata.put(
        metadata
          ..lastVideoSyncAt = DateTime.now()
          ..videoSyncCheckpoint = checkpoint,
      );
      return VideoSyncResult(
        added: added,
        updated: changed.length - added,
        removed: removed.length,
        total: scanned.length,
      );
    });
  }

  @override
  Future<String?> videoCheckpoint() async =>
      (await _metadata.get(LibraryMetadataCollection.singletonId))
          ?.videoSyncCheckpoint;

  @override
  Future<void> markVideosCheckedUnchanged() => _isar.writeTxn(() async {
    final metadata =
        await _metadata.get(LibraryMetadataCollection.singletonId) ??
        LibraryMetadataCollection();
    await _metadata.put(metadata..lastVideoSyncAt = DateTime.now());
  });

  @override
  Future<int> countVideos() => _videos.count();

  @override
  Future<List<VideoCollection>> getAllVideos() =>
      _videos.where().sortByCreatedAtDesc().findAll();

  @override
  Stream<List<VideoCollection>> watchAllVideos() =>
      _videos.where().sortByCreatedAtDesc().watch(fireImmediately: true);

  @override
  Stream<List<VideoCollection>> watchFavoriteVideos() => _videos
      .filter()
      .isFavoriteEqualTo(true)
      .sortByCreatedAtDesc()
      .watch(fireImmediately: true);

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
  Future<void> setFavorites(List<String> videoIds, {required bool favorite}) {
    return _isar.writeTxn(() async {
      final rows = await _videos.getAllByVideoId(videoIds);
      final changed = [
        for (final row in rows)
          if (row != null && row.isFavorite != favorite)
            row..isFavorite = favorite,
      ];
      if (changed.isNotEmpty) await _videos.putAll(changed);
    });
  }

  @override
  Future<void> removeVideos(List<String> videoIds) {
    return _isar.writeTxn(() async {
      await _videos.deleteAllByVideoId(videoIds);
      await _progress.deleteAllByVideoId(videoIds);
    });
  }

  @override
  Stream<List<VideoProgressCollection>> watchProgress() =>
      _progress.where().watch(fireImmediately: true);

  @override
  Future<VideoProgressCollection?> getProgress(String videoId) =>
      _progress.getByVideoId(videoId);

  @override
  Future<void> recordPlay(String videoId) => _updateProgress(
    videoId,
    (row) => row
      ..playCount += 1
      ..lastPlayedAt = DateTime.now(),
  );

  @override
  Future<void> savePlaybackPosition(String videoId, Duration position) =>
      _updateProgress(
        videoId,
        (row) => row
          ..positionMs = position.inMilliseconds
          ..lastPlayedAt = DateTime.now(),
      );

  /// Changes a video's progress row (made on first use); nothing for a
  /// video that's no longer in the library.
  Future<void> _updateProgress(
    String videoId,
    void Function(VideoProgressCollection row) update,
  ) {
    return _isar.writeTxn(() async {
      if (await _videos.getByVideoId(videoId) == null) return;
      final row =
          await _progress.getByVideoId(videoId) ??
          (VideoProgressCollection()..videoId = videoId);
      update(row);
      await _progress.put(row);
    });
  }
}
