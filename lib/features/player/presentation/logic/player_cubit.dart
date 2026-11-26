import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/domain/usecases/play_queue_usecase.dart';
import 'package:melodix/features/player/domain/usecases/edit_queue_usecase.dart';
import 'package:melodix/features/player/domain/usecases/playback_controls_usecase.dart';
import 'package:melodix/features/player/domain/usecases/restore_playback_session_usecase.dart';
import 'package:melodix/features/player/domain/usecases/watch_now_playing_usecase.dart';

/// App-wide player state. The mini player and the full player page both
/// read this one cubit, so they always show the same thing.
class PlayerCubit extends Cubit<NowPlaying> {
  PlayerCubit({
    required WatchNowPlayingUseCase watchNowPlaying,
    required this._playQueue,
    required this._controls,
    required this._restore,
    required this._editQueue,
    Random? random,
  }) : _random = random ?? Random(),
       super(watchNowPlaying.current) {
    _subscription = watchNowPlaying().listen((state) {
      if (!isClosed) emit(state);
    });
  }

  final PlayQueueUseCase _playQueue;
  final PlaybackControlsUseCase _controls;
  final RestorePlaybackSessionUseCase _restore;
  final EditQueueUseCase _editQueue;
  final Random _random;
  late final StreamSubscription<NowPlaying> _subscription;

  /// Plays [songs] starting at [index] (e.g. the list the user tapped in).
  /// [title] names that list in the queue ("Playing from …").
  Future<void> playSongs(List<Song> songs, int index, {String? title}) =>
      _playQueue(PlayQueueParams(songs, startIndex: index, title: title));

  /// Plays [songs] in shuffled order, starting from a random one. One
  /// step: the current queue is never reshuffled just to be replaced.
  Future<void> shufflePlay(List<Song> songs, {String? title}) async {
    if (songs.isEmpty) return;
    await _playQueue(
      PlayQueueParams(
        songs,
        startIndex: _random.nextInt(songs.length),
        title: title,
        shuffle: true,
      ),
    );
  }

  /// Plays [songs] right after the current song (or now, if nothing plays).
  Future<void> playNext(List<Song> songs) => _editQueue.playNext(songs);

  /// Adds [songs] at the end of the queue (or plays them, if nothing plays).
  Future<void> addToQueue(List<Song> songs) => _editQueue.addToQueue(songs);

  /// Jumps to a song in the current queue.
  Future<void> playAt(int index) => _controls.skipToIndex(index);

  Future<void> togglePlayPause() =>
      state.isPlaying ? _controls.pause() : _controls.play();

  Future<void> next() => _controls.next();
  Future<void> previous() => _controls.previous();
  Future<void> seek(Duration position) => _controls.seek(position);

  /// Off → repeat all → repeat one → off.
  Future<void> cycleRepeat() =>
      _controls.setRepeatMode(switch (state.repeatMode) {
        PlaybackRepeat.off => PlaybackRepeat.all,
        PlaybackRepeat.all => PlaybackRepeat.one,
        PlaybackRepeat.one => PlaybackRepeat.off,
      });

  Future<void> toggleShuffle() => _controls.setShuffle(!state.shuffle);

  /// Loads the last session (paused) on app start.
  Future<void> restore() => _restore();

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
