import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/video/presentation/playback/video_engine.dart';
import 'package:video_player/video_player.dart';

/// [VideoEngine] on the `video_player` package: the media library's
/// `content://` URI on Android (nothing is copied), a file on iOS.
VideoEngine videoPlayerEngine(Uri uri) =>
    VideoPlayerEngine(switch (uri.scheme) {
      'content' => VideoPlayerController.contentUri(uri),
      'file' => VideoPlayerController.file(File.fromUri(uri)),
      _ => VideoPlayerController.networkUrl(uri),
    });

class VideoPlayerEngine implements VideoEngine {
  VideoPlayerEngine(this._controller) {
    _controller.addListener(_sync);
  }

  final VideoPlayerController _controller;
  final ValueNotifier<VideoEngineValue> _value = ValueNotifier(
    const VideoEngineValue(),
  );

  /// [buildView] widgets on screen; the controller is released only when
  /// none are left.
  int _views = 0;
  bool _disposeRequested = false;
  bool _disposed = false;

  @override
  VideoEngineValue get value => _value.value;

  @override
  void addListener(VoidCallback listener) => _value.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _value.removeListener(listener);

  void _sync() {
    final v = _controller.value;
    _value.value = VideoEngineValue(
      isInitialized: v.isInitialized,
      duration: v.duration,
      position: v.position,
      bufferedTo: v.buffered.isEmpty ? Duration.zero : v.buffered.last.end,
      size: v.size,
      isPlaying: v.isPlaying,
      isBuffering: v.isBuffering,
      isCompleted: v.isCompleted,
    );
  }

  @override
  Future<void> initialize() => _controller.initialize();

  @override
  Future<void> play() async {
    if (!_disposeRequested) await _controller.play();
  }

  @override
  Future<void> pause() async {
    if (!_disposed) await _controller.pause();
  }

  @override
  Future<void> seekTo(Duration position) async {
    if (!_disposeRequested) await _controller.seekTo(position);
  }

  @override
  Future<void> setSpeed(double speed) async {
    if (!_disposeRequested) await _controller.setPlaybackSpeed(speed);
  }

  @override
  Widget buildView() => _EngineView(engine: this);

  @override
  Future<void> dispose() async {
    if (_disposeRequested) return;
    _disposeRequested = true;
    if (_views == 0) await _release();
  }

  void _attach() => _views++;

  void _detach() {
    _views--;
    if (_disposeRequested && _views == 0) unawaited(_release());
  }

  Future<void> _release() async {
    if (_disposed) return;
    _disposed = true;
    _controller.removeListener(_sync);
    await _controller.dispose();
    // Listeners still attached are widgets on their way out; they're
    // simply never called again.
  }
}

/// The picture, counted while on screen (see [VideoPlayerEngine.dispose]).
class _EngineView extends StatefulWidget {
  const _EngineView({required this.engine});

  final VideoPlayerEngine engine;

  @override
  State<_EngineView> createState() => _EngineViewState();
}

class _EngineViewState extends State<_EngineView> {
  @override
  void initState() {
    super.initState();
    widget.engine._attach();
  }

  @override
  void didUpdateWidget(_EngineView old) {
    super.didUpdateWidget(old);
    if (old.engine != widget.engine) {
      old.engine._detach();
      widget.engine._attach();
    }
  }

  @override
  void dispose() {
    widget.engine._detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => VideoPlayer(widget.engine._controller);
}
