import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/domain/usecases/get_video_playback_uri_usecase.dart';
import 'package:melodix/features/video/domain/usecases/toggle_video_favorite_usecase.dart';
import 'package:melodix/features/video/domain/usecases/video_progress_usecases.dart';
import 'package:melodix/features/video/presentation/logic/video_controller_factory.dart';
import 'package:video_player/video_player.dart';

enum VideoPlayerStatus { loading, ready, failed }

enum VideoPlayerError { missing, unplayable }

class VideoPlayerState extends Equatable {
  const VideoPlayerState({
    required this.queue,
    required this.index,
    this.status = VideoPlayerStatus.loading,
    this.controller,
    this.error,
    this.speed = 1,
  });

  /// The list the video was opened from (next / previous move in it).
  final List<Video> queue;
  final int index;
  final VideoPlayerStatus status;

  /// Set once the video is ready. Positions are read from it directly (so
  /// the time ticking never rebuilds anything but the seek bar).
  final VideoPlayerController? controller;
  final VideoPlayerError? error;
  final double speed;

  Video get video => queue[index];
  bool get hasNext => index < queue.length - 1;
  bool get hasPrevious => index > 0;

  VideoPlayerState copyWith({
    List<Video>? queue,
    int? index,
    VideoPlayerStatus? status,
    VideoPlayerController? Function()? controller,
    VideoPlayerError? Function()? error,
    double? speed,
  }) => VideoPlayerState(
    queue: queue ?? this.queue,
    index: index ?? this.index,
    status: status ?? this.status,
    controller: controller == null ? this.controller : controller(),
    error: error == null ? this.error : error(),
    speed: speed ?? this.speed,
  );

  @override
  List<Object?> get props => [queue, index, status, controller, error, speed];
}

/// Plays a video from a list, and remembers what was watched.
///
/// Learned from the music player:
/// * opening a video while another is still loading (fast next / next)
///   never lets the older one start afterwards: each open has a ticket and
///   stale ones throw their player away;
/// * a video that can't be opened is an error on screen with a way on (the
///   next video), never a silent jump to another one;
/// * where you stopped is saved every [saveEvery] while playing, on pause,
///   when switching video and on close, so a crash loses seconds at most;
/// * music pauses when a video starts (no two soundtracks at once).
class VideoPlayerCubit extends Cubit<VideoPlayerState> {
  VideoPlayerCubit({
    required List<Video> queue,
    required int index,
    required this._playbackUri,
    required this._recordPlay,
    required this._savePosition,
    required this._toggleFavorite,
    required this._pauseMusic,
    VideoControllerFactory? createController,
    this.saveEvery = const Duration(seconds: 15),
  }) : assert(index >= 0 && index < queue.length),
       _createController = createController ?? defaultVideoController,
       super(VideoPlayerState(queue: List.unmodifiable(queue), index: index));

  final GetVideoPlaybackUriUseCase _playbackUri;
  final RecordVideoPlayUseCase _recordPlay;
  final SaveVideoPositionUseCase _savePosition;
  final ToggleVideoFavoriteUseCase _toggleFavorite;
  final Future<void> Function() _pauseMusic;
  final VideoControllerFactory _createController;
  final Duration saveEvery;

  /// Within this distance of the end, a video restarts instead of resuming.
  static const Duration _resumeMargin = Duration(seconds: 5);

  int _ticket = 0;
  Timer? _saveTimer;
  bool _wasPlaying = false;

  /// Opens the video it was created with.
  Future<void> start() => _open(state.index);

  Future<void> next() async {
    if (state.hasNext) await _open(state.index + 1);
  }

  /// Back to the start of this video if it's past 5 s (like music), else
  /// the previous video.
  Future<void> previous() async {
    final controller = state.controller;
    if (controller != null &&
        controller.value.position > const Duration(seconds: 5)) {
      await seek(Duration.zero);
      return;
    }
    if (state.hasPrevious) await _open(state.index - 1);
  }

  /// Tries the current video again (after an error).
  Future<void> retry() => _open(state.index);

  Future<void> togglePlayPause() async {
    final controller = state.controller;
    if (controller == null) return;
    final value = controller.value;
    if (value.isPlaying) {
      await pause();
    } else {
      if (value.isCompleted) await controller.seekTo(Duration.zero);
      await _pauseMusic();
      await controller.play();
    }
  }

  /// Pauses. Where it stopped is saved by the pause itself (see
  /// [_onControllerChanged]), like any other pause: the system's, when the
  /// app leaves the screen, or the video ending.
  Future<void> pause() async => state.controller?.pause();

  Future<void> seek(Duration position) async {
    final controller = state.controller;
    if (controller == null) return;
    final duration = controller.value.duration;
    await controller.seekTo(
      position < Duration.zero
          ? Duration.zero
          : position > duration
          ? duration
          : position,
    );
  }

  /// Jumps [offset] (e.g. ±10 s for a double tap).
  Future<void> seekBy(Duration offset) async {
    final controller = state.controller;
    if (controller == null) return;
    await seek(controller.value.position + offset);
  }

  Future<void> setSpeed(double speed) async {
    emit(state.copyWith(speed: speed));
    await state.controller?.setPlaybackSpeed(speed);
  }

  /// ♥ / un-♥ the current video. Returns the new value; null if it
  /// couldn't be saved.
  Future<bool?> toggleFavorite() async {
    final id = state.video.id;
    final result = await _toggleFavorite(id);
    final isFavorite = result.fold((_) => null, (value) => value);
    if (isFavorite != null && !isClosed) {
      _updateVideo(id, (v) => v.copyWith(isFavorite: isFavorite));
    }
    return isFavorite;
  }

  Future<void> _open(int index) async {
    final ticket = ++_ticket;
    final previous = state.controller;
    await _closeController(previous, save: true);
    if (isClosed || ticket != _ticket) return;
    emit(
      state.copyWith(
        index: index,
        status: VideoPlayerStatus.loading,
        controller: () => null,
        error: () => null,
      ),
    );

    final video = state.video;
    final uri = await _playbackUri(video.id);
    if (isClosed || ticket != _ticket) return;
    if (uri == null) {
      emit(
        state.copyWith(
          status: VideoPlayerStatus.failed,
          error: () => VideoPlayerError.missing,
        ),
      );
      return;
    }

    final controller = _createController(uri);
    try {
      await controller.initialize();
    } catch (_) {
      unawaited(controller.dispose());
      if (isClosed || ticket != _ticket) return;
      emit(
        state.copyWith(
          status: VideoPlayerStatus.failed,
          error: () => VideoPlayerError.unplayable,
        ),
      );
      return;
    }
    if (isClosed || ticket != _ticket) {
      unawaited(controller.dispose()); // a newer video was asked for
      return;
    }

    final resumeAt = video.lastPosition;
    if (resumeAt > Duration.zero &&
        resumeAt < controller.value.duration - _resumeMargin) {
      await controller.seekTo(resumeAt);
    }
    await controller.setPlaybackSpeed(state.speed);
    if (isClosed || ticket != _ticket) {
      unawaited(controller.dispose());
      return;
    }
    controller.addListener(_onControllerChanged);
    emit(
      state.copyWith(
        status: VideoPlayerStatus.ready,
        controller: () => controller,
      ),
    );
    _saveTimer = Timer.periodic(saveEvery, (_) {
      if (controller.value.isPlaying) unawaited(_saveNow());
    });
    await _pauseMusic();
    await controller.play();
    unawaited(_recordPlay(video.id));
  }

  /// Saves on pause and on reaching the end (where the saved position is
  /// cleared: the video was watched).
  void _onControllerChanged() {
    final value = state.controller?.value;
    if (value == null) return;
    final playing = value.isPlaying;
    if (_wasPlaying && !playing) unawaited(_saveNow());
    _wasPlaying = playing;
  }

  Future<void> _saveNow() async {
    final controller = state.controller;
    if (controller == null || !controller.value.isInitialized) return;
    final id = state.video.id;
    final position = controller.value.isCompleted
        ? controller.value.duration
        : controller.value.position;
    // The list remembers it too, so going back to it resumes right here.
    _updateVideo(
      id,
      (v) => v.copyWith(
        lastPosition: position >= v.duration - const Duration(seconds: 10)
            ? Duration.zero
            : position,
        lastPlayedAt: DateTime.now(),
      ),
    );
    await _savePosition(id, position);
  }

  void _updateVideo(String id, Video Function(Video) update) {
    if (isClosed) return;
    final queue = [for (final v in state.queue) v.id == id ? update(v) : v];
    emit(state.copyWith(queue: List.unmodifiable(queue)));
  }

  Future<void> _closeController(
    VideoPlayerController? controller, {
    required bool save,
  }) async {
    _saveTimer?.cancel();
    _saveTimer = null;
    _wasPlaying = false;
    if (controller == null) return;
    controller.removeListener(_onControllerChanged);
    if (save) await _saveNow();
    await controller.pause();
    // The screen drops it in the next frame; dispose after that.
    unawaited(Future<void>.delayed(Duration.zero, controller.dispose));
  }

  @override
  Future<void> close() async {
    _ticket++;
    await _closeController(state.controller, save: true);
    return super.close();
  }
}
