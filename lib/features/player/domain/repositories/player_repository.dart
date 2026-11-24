import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/domain/entities/playback_progress.dart';

/// The app's single audio player.
abstract interface class PlayerRepository {
  NowPlaying get current;

  /// Emits the player state now and whenever it changes (not on position
  /// ticks: see [watchProgress]).
  Stream<NowPlaying> watch();

  PlaybackProgress get progress;

  /// Emits where playback is in the current song, now and as it moves.
  Stream<PlaybackProgress> watchProgress();

  /// Replaces the queue with [songs] and plays from [startIndex]. [title]
  /// names where the songs come from (shown in the queue). [shuffle], when
  /// given, turns shuffle on or off for this queue ([startIndex] plays
  /// first either way).
  Future<void> playQueue(
    List<Song> songs, {
    int startIndex = 0,
    String? title,
    bool? shuffle,
  });

  /// Jumps to the song at [index] in the queue and plays it.
  Future<void> skipToIndex(int index);

  /// Plays (restarting the queue if it had finished).
  Future<void> play();
  Future<void> pause();

  Future<void> seek(Duration position);

  /// Next song, if there is one.
  Future<void> next();

  /// Restarts the song if it's past the first few seconds, otherwise goes
  /// to the previous song (if any).
  Future<void> previous();
  Future<void> setRepeatMode(PlaybackRepeat mode);
  Future<void> setShuffle(bool enabled);

  /// Loads the last session (queue, song, position), paused. Does nothing
  /// if there's none or something is already playing.
  Future<void> restoreLastSession();
}
