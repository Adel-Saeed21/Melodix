import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/video/presentation/playback/video_engine.dart';

/// A [VideoEngine] without a platform: plays and seeks instantly, records
/// what was asked of it, and keeps the release contract (released only
/// once no view of it is on screen).
class FakeVideoEngine implements VideoEngine {
  FakeVideoEngine(
    this.uri, {
    this.length = const Duration(minutes: 10),
    this.size = const Size(1920, 1080),
    this.failInit = false,
    this.initGate,
  });

  final Uri uri;
  final Duration length;
  final Size size;
  final bool failInit;

  /// Holds [initialize] until completed (to test slow loads).
  final Completer<void>? initGate;

  final ValueNotifier<VideoEngineValue> _value = ValueNotifier(
    const VideoEngineValue(),
  );

  final List<Duration> seeks = [];
  double? speed;
  int views = 0;
  bool disposeRequested = false;

  /// Actually released (no view left).
  bool disposed = false;

  @override
  VideoEngineValue get value => _value.value;

  set _set(VideoEngineValue v) => _value.value = v;

  @override
  void addListener(VoidCallback listener) => _value.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _value.removeListener(listener);

  @override
  Future<void> initialize() async {
    await initGate?.future;
    if (failInit) throw StateError('unsupported codec');
    _set = VideoEngineValue(duration: length, size: size, isInitialized: true);
  }

  @override
  Future<void> play() async {
    if (disposeRequested) return;
    _set = value.copyWith(isPlaying: true, isCompleted: false);
  }

  @override
  Future<void> pause() async {
    if (disposed) return;
    _set = value.copyWith(isPlaying: false);
  }

  @override
  Future<void> seekTo(Duration position) async {
    seeks.add(position);
    _set = value.copyWith(position: position);
  }

  @override
  Future<void> setSpeed(double speed) async => this.speed = speed;

  @override
  Widget buildView() => _FakeView(engine: this);

  @override
  Future<void> dispose() async {
    disposeRequested = true;
    if (views == 0) disposed = true;
  }

  void _detach() {
    views--;
    if (disposeRequested && views == 0) disposed = true;
  }

  /// Moves playback on, as if time passed.
  void advanceTo(Duration position) =>
      _set = value.copyWith(position: position);

  /// Plays to the end.
  void finish() => _set = value.copyWith(
    position: length,
    isPlaying: false,
    isCompleted: true,
  );
}

class _FakeView extends StatefulWidget {
  const _FakeView({required this.engine});

  final FakeVideoEngine engine;

  @override
  State<_FakeView> createState() => _FakeViewState();
}

class _FakeViewState extends State<_FakeView> {
  @override
  void initState() {
    super.initState();
    widget.engine.views++;
  }

  @override
  void dispose() {
    widget.engine._detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      const ColoredBox(color: Colors.black, key: ValueKey('fake-video'));
}
