import 'dart:async';

import 'package:melodix/features/video/domain/usecases/video_progress_usecases.dart';
import 'package:melodix/features/video/presentation/playback/video_engine.dart';

/// Remembers how much of the playing video was watched: where to resume,
/// saving its place, and counting the play.
///
/// The place is saved whenever playback stops (a pause, the system
/// pausing it, the end) and every [saveEvery] while it plays, so a crash
/// loses seconds at most. Saving only writes to storage: nothing on screen
/// changes for it.
class VideoProgressTracker {
  VideoProgressTracker({
    required this._progress,
    required this._savePosition,
    required this._recordPlay,
    this.saveEvery = const Duration(seconds: 15),
  });

  final GetVideoProgressUseCase _progress;
  final SaveVideoPositionUseCase _savePosition;
  final RecordVideoPlayUseCase _recordPlay;
  final Duration saveEvery;

  VideoEngine? _engine;
  String? _videoId;
  Timer? _timer;
  bool _wasPlaying = false;

  /// Where to start [videoId] (of [length]): where it stopped last time,
  /// unless that was the end. Null: from the start.
  Future<Duration?> resumePosition(String videoId, Duration length) async {
    final saved = await _progress(videoId);
    return saved != null && saved.canResume(length) ? saved.position : null;
  }

  /// Starts following [engine], playing [videoId], and counts the play.
  void track(VideoEngine engine, String videoId) {
    _stopFollowing();
    _engine = engine;
    _videoId = videoId;
    _wasPlaying = engine.value.isPlaying;
    engine.addListener(_onChange);
    _timer = Timer.periodic(saveEvery, (_) {
      if (engine.value.isPlaying) unawaited(saveNow());
    });
    unawaited(_recordPlay(videoId));
  }

  /// Saves the place now and stops following the video.
  Future<void> untrack() async {
    final save = saveNow();
    _stopFollowing();
    await save;
  }

  /// Saves where the followed video is.
  Future<void> saveNow() async {
    final engine = _engine;
    final videoId = _videoId;
    if (engine == null || videoId == null) return;
    final value = engine.value;
    if (!value.isInitialized) return;
    await _savePosition(
      videoId,
      value.isCompleted ? value.duration : value.position,
      length: value.duration,
    );
  }

  void _onChange() {
    final playing = _engine?.value.isPlaying ?? false;
    if (_wasPlaying && !playing) unawaited(saveNow());
    _wasPlaying = playing;
  }

  void _stopFollowing() {
    _timer?.cancel();
    _timer = null;
    _engine?.removeListener(_onChange);
    _engine = null;
    _videoId = null;
    _wasPlaying = false;
  }
}
