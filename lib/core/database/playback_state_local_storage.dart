import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/collections/playback_state_collection.dart';
import 'package:melodix/core/database/collections/song_collection.dart';

/// The saved player state, resolved against the songs still on the device.
class SavedPlayback {
  const SavedPlayback({
    required this.queue,
    required this.originalQueue,
    required this.currentIndex,
    required this.position,
    required this.shuffle,
    required this.repeatMode,
    required this.speed,
    required this.source,
    required this.sourceId,
  });

  final List<SongCollection> queue;
  final List<SongCollection> originalQueue;
  final int currentIndex;
  final Duration position;
  final bool shuffle;
  final PlayerRepeatMode repeatMode;
  final double speed;
  final PlaybackSource source;
  final int? sourceId;

  SongCollection get currentSong => queue[currentIndex];

  /// Builds the restorable state from [state], dropping songs that are no
  /// longer in [songsById]. Returns null if nothing playable is left.
  ///
  /// If the song that was playing is gone, playback continues with the next
  /// remaining song from the start.
  static SavedPlayback? resolve(
    PlaybackStateCollection state,
    Map<int, SongCollection> songsById,
  ) {
    final queue = <SongCollection>[];
    var newIndex = 0;
    var currentStillExists = false;

    for (var i = 0; i < state.queueSongIds.length; i++) {
      final song = songsById[state.queueSongIds[i]];
      if (song == null) continue;
      if (i < state.currentIndex) newIndex++;
      if (i == state.currentIndex) currentStillExists = true;
      queue.add(song);
    }
    if (queue.isEmpty) return null;

    if (newIndex >= queue.length) newIndex = queue.length - 1;

    return SavedPlayback(
      queue: queue,
      originalQueue: [
        for (final id in state.originalQueueSongIds)
          if (songsById[id] != null) songsById[id]!,
      ],
      currentIndex: newIndex,
      position: currentStillExists ? state.position : Duration.zero,
      shuffle: state.shuffle,
      repeatMode: state.repeatMode,
      speed: state.speed,
      source: state.source,
      sourceId: state.sourceId,
    );
  }
}

/// Saves the player state so music resumes where the user left off.
///
/// Suggested use from the player:
/// * [saveQueue] when a new queue starts playing.
/// * [savePosition] every few seconds while playing, and on pause, song
///   change and when the app goes to the background.
/// * [saveSettings] when shuffle / repeat / speed change.
/// * [loadPlayback] once on startup to restore (paused) playback.
abstract interface class PlaybackStateLocalStorage {
  Future<SavedPlayback?> loadPlayback();

  Future<void> saveQueue({
    required List<int> queueSongIds,
    required int currentIndex,
    List<int>? originalQueueSongIds,
    PlaybackSource source = PlaybackSource.allSongs,
    int? sourceId,
    Duration position = Duration.zero,
  });

  Future<void> savePosition({
    required int currentIndex,
    required Duration position,
  });

  Future<void> saveSettings({
    bool? shuffle,
    List<int>? queueSongIds,
    int? currentIndex,
    PlayerRepeatMode? repeatMode,
    double? speed,
  });

  /// Forgets the saved state (e.g. when the user stops playback).
  Future<void> clear();
}

class PlaybackStateLocalStorageImpl implements PlaybackStateLocalStorage {
  PlaybackStateLocalStorageImpl(this._isar);

  final Isar _isar;

  IsarCollection<PlaybackStateCollection> get _state =>
      _isar.playbackStateCollections;

  @override
  Future<SavedPlayback?> loadPlayback() async {
    final state = await _state.get(PlaybackStateCollection.singletonId);
    if (state == null || state.queueSongIds.isEmpty) return null;

    final ids = {...state.queueSongIds, ...state.originalQueueSongIds};
    final songs = await _isar.songCollections.getAll(ids.toList());
    return SavedPlayback.resolve(state, {
      for (final s in songs.whereType<SongCollection>()) s.id: s,
    });
  }

  @override
  Future<void> saveQueue({
    required List<int> queueSongIds,
    required int currentIndex,
    List<int>? originalQueueSongIds,
    PlaybackSource source = PlaybackSource.allSongs,
    int? sourceId,
    Duration position = Duration.zero,
  }) {
    return _update((s) {
      s
        ..queueSongIds = [...queueSongIds]
        ..originalQueueSongIds = [...(originalQueueSongIds ?? queueSongIds)]
        ..currentIndex = currentIndex
        ..positionMs = position.inMilliseconds
        ..source = source
        ..sourceId = sourceId;
    });
  }

  @override
  Future<void> savePosition({
    required int currentIndex,
    required Duration position,
  }) {
    return _update((s) {
      s
        ..currentIndex = currentIndex
        ..positionMs = position.inMilliseconds;
    });
  }

  @override
  Future<void> saveSettings({
    bool? shuffle,
    List<int>? queueSongIds,
    int? currentIndex,
    PlayerRepeatMode? repeatMode,
    double? speed,
  }) {
    return _update((s) {
      if (shuffle != null) s.shuffle = shuffle;
      if (queueSongIds != null) s.queueSongIds = [...queueSongIds];
      if (currentIndex != null) s.currentIndex = currentIndex;
      if (repeatMode != null) s.repeatMode = repeatMode;
      if (speed != null) s.speed = speed;
    });
  }

  @override
  Future<void> clear() =>
      _isar.writeTxn(() => _state.delete(PlaybackStateCollection.singletonId));

  Future<void> _update(void Function(PlaybackStateCollection state) change) {
    return _isar.writeTxn(() async {
      final state =
          await _state.get(PlaybackStateCollection.singletonId) ??
          PlaybackStateCollection();
      change(state);
      state.updatedAt = DateTime.now();
      await _state.put(state);
    });
  }
}
