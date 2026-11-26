import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/domain/entities/playback_progress.dart';
import 'package:melodix/features/player/domain/repositories/player_repository.dart';

/// The sleep timer: off, counting down, or waiting for the song to end.
class SleepTimerState extends Equatable {
  const SleepTimerState({this.remaining, this.endOfSong = false});

  static const off = SleepTimerState();

  /// Time left; null when not counting down.
  final Duration? remaining;

  /// Stops when the current song ends.
  final bool endOfSong;

  bool get isActive => remaining != null || endOfSong;

  @override
  List<Object?> get props => [remaining, endOfSong];
}

/// Stops the music after a while, or at the end of the song. The last
/// [fade] fades the music out (the app's own volume, not the phone's),
/// so falling asleep isn't interrupted by a sudden stop.
class SleepTimerCubit extends Cubit<SleepTimerState> {
  SleepTimerCubit(this._player) : super(SleepTimerState.off);

  final PlayerRepository _player;

  /// The choices offered (minutes).
  static const List<int> minuteChoices = [5, 15, 30, 45, 60, 90];

  static const Duration fade = Duration(seconds: 10);
  static const Duration _tick = Duration(seconds: 1);

  Timer? _timer;
  StreamSubscription<NowPlaying>? _songs;
  StreamSubscription<PlaybackProgress>? _progress;
  bool _faded = false;

  /// Counts down [duration], then pauses.
  void start(Duration duration) {
    _clear();
    emit(SleepTimerState(remaining: duration));
    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  /// Adds [extra] to a running countdown.
  void extend(Duration extra) {
    final left = state.remaining;
    if (left == null) return;
    _restoreVolume();
    emit(SleepTimerState(remaining: left + extra));
  }

  /// Pauses when the song playing now ends (the next one waits, paused,
  /// at its start).
  void stopAtEndOfSong() {
    _clear();
    final song = _player.current.currentSong?.id;
    emit(const SleepTimerState(endOfSong: true));
    _songs = _player.watch().listen((now) {
      if (now.currentSong?.id != song || now.isCompleted) {
        unawaited(_stopForTheNight(rewind: !now.isCompleted));
      }
    });
    // Repeat-one: the same song starts over.
    var last = _player.progress.position;
    _progress = _player.watchProgress().listen((progress) {
      final duration = _player.current.duration;
      final wrapped =
          duration > _tick * 4 &&
          last > duration - _tick * 3 &&
          progress.position < _tick * 2;
      last = progress.position;
      if (wrapped) unawaited(_stopForTheNight(rewind: true));
    });
  }

  void cancel() {
    _clear();
    emit(SleepTimerState.off);
  }

  void _onTick() {
    final left = state.remaining;
    if (left == null) return;
    final next = left - _tick;
    if (next <= Duration.zero) {
      unawaited(_stopForTheNight(rewind: false));
      return;
    }
    emit(SleepTimerState(remaining: next));
    // Paused already: nothing to fade.
    if (next < fade && _player.current.isPlaying) {
      _faded = true;
      unawaited(_player.setVolume(next.inMilliseconds / fade.inMilliseconds));
    }
  }

  Future<void> _stopForTheNight({required bool rewind}) async {
    // Stay quiet until paused (no burst of sound at the end).
    _faded = false;
    _clear();
    emit(SleepTimerState.off);
    await _player.pause();
    // The next song started for a moment: back to its start.
    if (rewind) await _player.seek(Duration.zero);
    await _player.setVolume(1);
  }

  void _restoreVolume() {
    if (_faded) unawaited(_player.setVolume(1));
    _faded = false;
  }

  void _clear() {
    _timer?.cancel();
    _timer = null;
    unawaited(_songs?.cancel());
    _songs = null;
    unawaited(_progress?.cancel());
    _progress = null;
    _restoreVolume();
  }

  @override
  Future<void> close() {
    _clear();
    return super.close();
  }
}
