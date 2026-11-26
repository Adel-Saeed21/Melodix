import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/service/playback_coordinator.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/domain/usecases/get_video_playback_uri_usecase.dart';
import 'package:melodix/features/video/presentation/playback/video_engine.dart';
import 'package:melodix/features/video/presentation/playback/video_player_engine.dart';
import 'package:melodix/features/video/presentation/playback/video_progress_tracker.dart';

/// [idle]: no video open (nothing to show, not even the small window).
enum VideoPlayerStatus { idle, loading, ready, failed }

enum VideoPlayerError { missing, unplayable }

class VideoPlayerState extends Equatable {
  const VideoPlayerState({
    this.queue = const [],
    this.index = 0,
    this.status = VideoPlayerStatus.idle,
    this.engine,
    this.error,
    this.speed = 1,
    this.expanded = false,
  });

  /// The list the video was opened from (next / previous move in it).
  final List<Video> queue;
  final int index;
  final VideoPlayerStatus status;

  /// Set once the video is ready. Positions are read from it directly (so
  /// the time ticking never rebuilds anything but the seek bar).
  final VideoEngine? engine;
  final VideoPlayerError? error;
  final double speed;

  /// The full-screen player is showing (else, if [isActive], the small
  /// window is).
  final bool expanded;

  /// A video is open: playing, paused, loading or failed.
  bool get isActive => status != VideoPlayerStatus.idle;

  /// The open video (after [VideoPlayerCubit.stop]: the last one).
  Video get video => queue[index];
  bool get hasNext => index < queue.length - 1;
  bool get hasPrevious => index > 0;

  VideoPlayerState copyWith({
    List<Video>? queue,
    int? index,
    VideoPlayerStatus? status,
    VideoEngine? Function()? engine,
    VideoPlayerError? Function()? error,
    double? speed,
    bool? expanded,
  }) => VideoPlayerState(
    queue: queue ?? this.queue,
    index: index ?? this.index,
    status: status ?? this.status,
    engine: engine == null ? this.engine : engine(),
    error: error == null ? this.error : error(),
    speed: speed ?? this.speed,
    expanded: expanded ?? this.expanded,
  );

  @override
  List<Object?> get props => [
    queue,
    index,
    status,
    engine,
    error,
    speed,
    expanded,
  ];
}

/// The app's one video session: which list is open, which video in it,
/// and the controls (play, pause, seek, next…). It lives as long as the
/// app, so leaving the full player keeps the video going in the small
/// window ([VideoPlayerState.expanded] false); [stop] ends it.
///
/// It leaves the rest to its helpers:
/// * the video itself to a [VideoEngine] (made by [VideoEngineFactory]);
/// * resume, saving progress and counting plays to [VideoProgressTracker];
/// * music vs video to the [PlaybackCoordinator].
///
/// Opening a video while another still loads never lets the older one
/// start afterwards: each open has a ticket and stale ones are released.
/// A video that can't be opened is an error on screen with a way on, never
/// a silent jump to another one.
class VideoPlayerCubit extends Cubit<VideoPlayerState> {
  VideoPlayerCubit({
    required this._playbackUri,
    required this._progress,
    required this._coordinator,
    VideoEngineFactory? createEngine,
  }) : _createEngine = createEngine ?? videoPlayerEngine,
       super(const VideoPlayerState()) {
    _musicStarted = _coordinator.musicStarted.listen((_) => pause());
  }

  final GetVideoPlaybackUriUseCase _playbackUri;
  final VideoProgressTracker _progress;
  final PlaybackCoordinator _coordinator;
  final VideoEngineFactory _createEngine;

  int _ticket = 0;
  late final StreamSubscription<void> _musicStarted;

  /// Plays [queue] from [index] (replacing whatever was open; its place is
  /// saved first).
  Future<void> open(List<Video> queue, int index) {
    assert(index >= 0 && index < queue.length);
    return _open(index, queue: List.unmodifiable(queue));
  }

  /// Puts [videos] right after the current one: they play next. With no
  /// video open, they start playing; returns true then (the caller shows
  /// the player).
  bool playNext(List<Video> videos) => _add(videos, next: true);

  /// Puts [videos] at the end of the list. With no video open, they start
  /// playing; returns true then.
  bool addToQueue(List<Video> videos) => _add(videos, next: false);

  bool _add(List<Video> videos, {required bool next}) {
    if (videos.isEmpty || isClosed) return false;
    if (!state.isActive) {
      unawaited(open(videos, 0));
      return true;
    }
    final queue = state.queue;
    final at = next ? state.index + 1 : queue.length;
    // Inserted after the current video: its index (and playback) stay.
    emit(
      state.copyWith(
        queue: List.unmodifiable([
          ...queue.sublist(0, at),
          ...videos,
          ...queue.sublist(at),
        ]),
      ),
    );
    return false;
  }

  /// Ends the session: saves where it stopped and releases the video.
  Future<void> stop() async {
    if (!state.isActive) return;
    _ticket++;
    await _release(state.engine);
    // The last video stays in the state (widgets still on their way out
    // may read it); only the status says it's over.
    if (!isClosed) {
      emit(
        state.copyWith(
          status: VideoPlayerStatus.idle,
          engine: () => null,
          error: () => null,
          expanded: false,
        ),
      );
    }
  }

  /// Whether the full-screen player is the one showing the video.
  void setExpanded(bool expanded) {
    if (!isClosed && state.expanded != expanded) {
      emit(state.copyWith(expanded: expanded));
    }
  }

  Future<void> next() async {
    if (state.hasNext) await _open(state.index + 1);
  }

  /// Back to the start of this video if it's past 5 s (like music), else
  /// the previous video.
  Future<void> previous() async {
    final engine = state.engine;
    if (engine != null && engine.value.position > const Duration(seconds: 5)) {
      await seek(Duration.zero);
      return;
    }
    if (state.hasPrevious) await _open(state.index - 1);
  }

  /// Jumps to the video at [index] in the list (e.g. from "Up next").
  Future<void> playAt(int index) async {
    if (!state.isActive || index == state.index) return;
    if (index < 0 || index >= state.queue.length) return;
    await _open(index);
  }

  /// Tries the current video again (after an error).
  Future<void> retry() async {
    if (state.isActive) await _open(state.index);
  }

  Future<void> togglePlayPause() async {
    final engine = state.engine;
    if (engine == null) return;
    final value = engine.value;
    if (value.isPlaying) {
      await pause();
    } else {
      if (value.isCompleted) await engine.seekTo(Duration.zero);
      await _coordinator.videoStarting();
      await engine.play();
    }
  }

  /// Pauses (its place is saved by the tracker, as for any pause).
  Future<void> pause() async => state.engine?.pause();

  Future<void> seek(Duration position) async {
    final engine = state.engine;
    if (engine == null) return;
    final duration = engine.value.duration;
    await engine.seekTo(
      position < Duration.zero
          ? Duration.zero
          : position > duration
          ? duration
          : position,
    );
  }

  /// Jumps [offset] (e.g. ±10 s for a double tap).
  Future<void> seekBy(Duration offset) async {
    final engine = state.engine;
    if (engine == null) return;
    await seek(engine.value.position + offset);
  }

  Future<void> setSpeed(double speed) async {
    emit(state.copyWith(speed: speed));
    await state.engine?.setSpeed(speed);
  }

  Future<void> _open(int index, {List<Video>? queue}) async {
    final ticket = ++_ticket;
    final previous = state.engine;
    // Loading is emitted before the first await, so the session is active
    // as soon as open() returns: the player route (which redirects away
    // when no video is open) can be pushed right after it.
    emit(
      state.copyWith(
        queue: queue,
        index: index,
        status: VideoPlayerStatus.loading,
        engine: () => null,
        error: () => null,
      ),
    );
    // Saves the old video's place and releases it (once off screen).
    await _release(previous);
    if (isClosed || ticket != _ticket) return;

    final video = state.video;
    final uri = await _playbackUri(video.id);
    if (isClosed || ticket != _ticket) return;
    if (uri == null) {
      _fail(VideoPlayerError.missing);
      return;
    }

    final engine = _createEngine(uri);
    try {
      await engine.initialize();
    } catch (_) {
      unawaited(engine.dispose());
      if (!isClosed && ticket == _ticket) _fail(VideoPlayerError.unplayable);
      return;
    }
    bool stale() => isClosed || ticket != _ticket;
    if (stale()) return unawaited(engine.dispose());

    final resumeAt = await _progress.resumePosition(
      video.id,
      engine.value.duration,
    );
    if (resumeAt != null) await engine.seekTo(resumeAt);
    await engine.setSpeed(state.speed);
    if (stale()) return unawaited(engine.dispose());

    emit(state.copyWith(status: VideoPlayerStatus.ready, engine: () => engine));
    await _coordinator.videoStarting();
    // Closed or replaced while the music paused: don't start or count it.
    if (stale()) return;
    await engine.play();
    _progress.track(engine, video.id);
  }

  void _fail(VideoPlayerError error) => emit(
    state.copyWith(status: VideoPlayerStatus.failed, error: () => error),
  );

  /// Saves the place and releases [engine] (once nothing shows it).
  Future<void> _release(VideoEngine? engine) async {
    if (engine == null) return;
    await _progress.untrack();
    await engine.pause();
    await engine.dispose();
  }

  @override
  Future<void> close() async {
    await _musicStarted.cancel();
    _ticket++;
    await _release(state.engine);
    return super.close();
  }
}
