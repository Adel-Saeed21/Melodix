import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:melodix/features/video/presentation/widgets/player/controller_selector.dart';
import 'package:melodix/features/video/presentation/widgets/player/seek_jump_bubble.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_controls_layer.dart';
import 'package:video_player/video_player.dart';

/// What's drawn over the video: tap to show / hide, double-tap a side to
/// jump 10 s, and the buttons (hidden 3 s after the last touch while
/// playing; always shown when paused).
class VideoPlayerControls extends StatefulWidget {
  const VideoPlayerControls({
    super.key,
    required this.controller,
    required this.onRotate,
    this.hideAfter = const Duration(seconds: 3),
  });

  final VideoPlayerController controller;
  final VoidCallback onRotate;
  final Duration hideAfter;

  static const List<double> speeds = [0.5, 0.75, 1, 1.25, 1.5, 2];
  static const Duration doubleTapJump = Duration(seconds: 10);

  @override
  State<VideoPlayerControls> createState() => _VideoPlayerControlsState();
}

class _VideoPlayerControlsState extends State<VideoPlayerControls> {
  bool _visible = true;
  bool _dragging = false;
  Timer? _hideTimer;

  /// The last double-tap jump, shown briefly on its side; repeated taps
  /// add up ("+30s").
  int _jumpSeconds = 0;
  Timer? _jumpTimer;
  Offset? _doubleTapAt;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onPlayerChanged);
    _scheduleHide();
  }

  @override
  void didUpdateWidget(VideoPlayerControls old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onPlayerChanged);
      widget.controller.addListener(_onPlayerChanged);
      _show();
    }
  }

  bool _wasPlaying = false;

  void _onPlayerChanged() {
    final playing = widget.controller.value.isPlaying;
    if (playing == _wasPlaying) return;
    _wasPlaying = playing;
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
      if (mounted && !_dragging && widget.controller.value.isPlaying) {
        setState(() => _visible = false);
      }
    });
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
    final step = VideoPlayerControls.doubleTapJump.inSeconds;
    final cubit = context.read<VideoPlayerCubit>();
    unawaited(
      cubit.seekBy(VideoPlayerControls.doubleTapJump * (forward ? 1 : -1)),
    );
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
    widget.controller.removeListener(_onPlayerChanged);
    _hideTimer?.cancel();
    _jumpTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            child: ControllerSelector<bool>(
              controller: widget.controller,
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
                controller: widget.controller,
                onRotate: widget.onRotate,
                onTouched: _show,
                onDragging: (dragging) {
                  _dragging = dragging;
                  if (!dragging) _scheduleHide();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
