import 'package:melodix/core/l10n/l10n.dart';

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:melodix/features/video/presentation/widgets/player/engine_selector.dart';
import 'package:melodix/features/video/presentation/widgets/player/seek_jump_bubble.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_transport_buttons.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_controls_layer.dart';
import 'package:melodix/features/video/presentation/playback/video_engine.dart';

/// What's drawn over the video: tap to show / hide, double-tap a side to
/// jump (by the step chosen in Settings), and the buttons (hidden 3 s after the last touch while
/// playing; always shown when paused).
class VideoPlayerControls extends StatefulWidget {
  const VideoPlayerControls({
    super.key,
    required this.engine,
    required this.onRotate,
    required this.fill,
    required this.onToggleFill,
    this.hideAfter = const Duration(seconds: 3),
  });

  final VideoEngine engine;
  final VoidCallback onRotate;
  final bool fill;
  final VoidCallback onToggleFill;
  final Duration hideAfter;

  static const List<double> speeds = [0.5, 0.75, 1, 1.25, 1.5, 2];

  @override
  State<VideoPlayerControls> createState() => _VideoPlayerControlsState();
}

class _VideoPlayerControlsState extends State<VideoPlayerControls> {
  bool _visible = true;
  bool _dragging = false;

  /// Locked: touches do nothing but show Unlock (no accidental pauses,
  /// seeks or pulls down, e.g. holding the phone or in a pocket).
  bool _locked = false;
  Timer? _hideTimer;

  /// The last double-tap jump, shown briefly on its side; repeated taps
  /// add up ("+30s").
  int _jumpSeconds = 0;
  Timer? _jumpTimer;
  Offset? _doubleTapAt;

  @override
  void initState() {
    super.initState();
    widget.engine.addListener(_onPlayerChanged);
    _scheduleHide();
  }

  @override
  void didUpdateWidget(VideoPlayerControls old) {
    super.didUpdateWidget(old);
    if (old.engine != widget.engine) {
      old.engine.removeListener(_onPlayerChanged);
      widget.engine.addListener(_onPlayerChanged);
      _show();
    }
  }

  bool _wasPlaying = false;

  void _onPlayerChanged() {
    final playing = widget.engine.value.isPlaying;
    if (playing == _wasPlaying) return;
    _wasPlaying = playing;
    if (_locked) return; // stays out of the way
    // Paused (or ended): keep the controls up. Playing: hide them soon.
    if (!playing) {
      _hideTimer?.cancel();
      if (!_visible) setState(() => _visible = true);
    } else {
      _scheduleHide();
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(widget.hideAfter, () {
      // Locked, Unlock hides again whatever the video is doing.
      if (mounted && !_dragging && (_locked || widget.engine.value.isPlaying)) {
        setState(() => _visible = false);
      }
    });
  }

  void _lock() {
    setState(() => _locked = true);
    _scheduleHide();
  }

  void _unlock() {
    setState(() => _locked = false);
    _show();
  }

  void _show() {
    if (!_visible) setState(() => _visible = true);
    _scheduleHide();
  }

  void _toggle() {
    if (_visible) {
      _hideTimer?.cancel();
      setState(() => _visible = false);
    } else {
      _show();
    }
  }

  void _onDoubleTap(double width) {
    final at = _doubleTapAt;
    if (at == null) return;
    final forward = at.dx > width / 2;
    final jump = videoSeekStepOf(context);
    final step = jump.inSeconds;
    final cubit = context.read<VideoPlayerCubit>();
    unawaited(cubit.seekBy(jump * (forward ? 1 : -1)));
    setState(() {
      // Same direction as the last jump (still shown): add up.
      _jumpSeconds = (_jumpSeconds != 0 && (_jumpSeconds > 0) == forward)
          ? _jumpSeconds + (forward ? step : -step)
          : (forward ? step : -step);
    });
    _jumpTimer?.cancel();
    _jumpTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _jumpSeconds = 0);
    });
  }

  @override
  void dispose() {
    widget.engine.removeListener(_onPlayerChanged);
    _hideTimer?.cancel();
    _jumpTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_locked) return _lockedOverlay();
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggle,
            onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
            onDoubleTap: () => _onDoubleTap(constraints.maxWidth),
          ),
          if (_jumpSeconds != 0)
            Align(
              alignment: _jumpSeconds > 0
                  ? const Alignment(0.7, 0)
                  : const Alignment(-0.7, 0),
              child: IgnorePointer(
                child: SeekJumpBubble(seconds: _jumpSeconds),
              ),
            ),
          // Buffering: a spinner even while the controls are hidden.
          IgnorePointer(
            child: EngineSelector<bool>(
              engine: widget.engine,
              select: (v) => v.isBuffering && !v.isCompleted,
              builder: (context, buffering) => buffering
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          IgnorePointer(
            ignoring: !_visible,
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: VideoControlsLayer(
                engine: widget.engine,
                onRotate: widget.onRotate,
                onTouched: _show,
                onDragging: (dragging) {
                  _dragging = dragging;
                  if (!dragging) _scheduleHide();
                },
                fill: widget.fill,
                onToggleFill: widget.onToggleFill,
                onLock: _lock,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// While locked: a tap only shows Unlock (for a few seconds).
  Widget _lockedOverlay() {
    final padding = MediaQuery.paddingOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        // Takes vertical drags too, so pulling down doesn't minimize.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _show,
          onVerticalDragUpdate: (_) {},
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: padding.bottom + 32,
          child: IgnorePointer(
            ignoring: !_visible,
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Center(
                child: FilledButton.tonalIcon(
                  onPressed: _unlock,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.lock_open_rounded),
                  label: Text(context.l10n.unlockControls),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
