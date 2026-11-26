import 'dart:async';

import 'package:melodix/core/database/collections/playback_state_collection.dart';
import 'package:melodix/core/database/playback_state_local_storage.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';

/// Saves the listening session (queue, song, position, repeat, shuffle) so
/// it can be restored, paused, after a restart.
///
/// The position is saved on demand (pause, seek, song change) and every
/// [interval] while playing ([whilePlaying]): a restart resumes close to
/// where it was, without rewriting the saved session (which holds the whole
/// queue) every few seconds.
class PlaybackSessionSaver {
  PlaybackSessionSaver(
    this._storage, {
    this.interval = const Duration(seconds: 30),
  });

  final PlaybackStateLocalStorage _storage;
  final Duration interval;
  Timer? _timer;

  Future<SavedPlayback?> load() => _storage.loadPlayback();

  void saveQueue(List<Song> songs, {required int currentIndex}) => unawaited(
    _storage.saveQueue(
      queueSongIds: [for (final song in songs) song.id],
      currentIndex: currentIndex,
    ),
  );

  Future<void> savePosition({
    required int currentIndex,
    required Duration position,
  }) => _storage.savePosition(currentIndex: currentIndex, position: position);

  void saveRepeat(PlaybackRepeat mode) =>
      unawaited(_storage.saveSettings(repeatMode: toStored(mode)));

  void saveShuffle(bool enabled) =>
      unawaited(_storage.saveSettings(shuffle: enabled));

  /// While playing, calls [save] every [interval]; call [stopped] when
  /// playback stops.
  void whilePlaying(void Function() save) =>
      _timer ??= Timer.periodic(interval, (_) => save());

  void stopped() {
    _timer?.cancel();
    _timer = null;
  }

  static PlayerRepeatMode toStored(PlaybackRepeat mode) => switch (mode) {
    PlaybackRepeat.off => PlayerRepeatMode.off,
    PlaybackRepeat.all => PlayerRepeatMode.all,
    PlaybackRepeat.one => PlayerRepeatMode.one,
  };

  static PlaybackRepeat fromStored(PlayerRepeatMode mode) => switch (mode) {
    PlayerRepeatMode.off => PlaybackRepeat.off,
    PlayerRepeatMode.all => PlaybackRepeat.all,
    PlayerRepeatMode.one => PlaybackRepeat.one,
  };
}
