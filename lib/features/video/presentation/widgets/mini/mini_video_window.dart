import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:melodix/features/video/presentation/widgets/mini/mini_video_audio_card.dart';
import 'package:melodix/features/video/presentation/widgets/mini/mini_video_card.dart';

/// The video in a small window floating over the app, so it keeps playing
/// while you browse. Drag it to any corner (it snaps there); throw it off
/// the side to close it; tap it to go back to full screen.
///
/// Listened to as audio, the same window is a slim card with the audio
/// controls ([MiniVideoAudioCard]); switching reshapes it in its corner.
class MiniVideoWindow extends StatefulWidget {
  const MiniVideoWindow({
    super.key,
    required this.state,
    required this.onExpand,
    required this.onClose,
    this.clearance = portraitClearance,
  });

  final VideoPlayerState state;
  final VoidCallback onExpand;
  final VoidCallback onClose;

  /// Room kept free for the app's bars, by where they are:
  /// portrait: the nav bar along the bottom (and the music bar above it);
  /// sideways: the nav rail down the left (and the music bar at the bottom).
  static EdgeInsets clearanceFor({
    required bool landscape,
    required bool musicBar,
  }) => landscape
      ? EdgeInsets.only(left: 96, bottom: musicBar ? 88 : 12)
      : EdgeInsets.only(bottom: musicBar ? 176 : 104);

  static const EdgeInsets portraitClearance = EdgeInsets.only(bottom: 104);

  /// Room left free for the app's bars (see [clearanceFor]).
  final EdgeInsets clearance;
  static const double margin = 12;

  @override
  State<MiniVideoWindow> createState() => _MiniVideoWindowState();
}

class _MiniVideoWindowState extends State<MiniVideoWindow> {
  /// Where it rests: a corner (x and y each -1 or 1).
  Alignment _corner = Alignment.bottomRight;

  /// Top-left while a finger moves it; null at rest.
  Offset? _dragAt;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size;
    final size = _windowSize(screen);
    final clear = widget.clearance;
    final area = Rect.fromLTRB(
      MiniVideoWindow.margin + media.padding.left + clear.left,
      MiniVideoWindow.margin + media.padding.top + clear.top,
      screen.width - MiniVideoWindow.margin - media.padding.right - clear.right,
      screen.height - clear.bottom - media.padding.bottom,
    );
    final rest = Offset(
      _corner.x < 0 ? area.left : area.right - size.width,
      _corner.y < 0 ? area.top : area.bottom - size.height,
    );
    final at = _dragAt ?? rest;

    return AnimatedPositioned(
      duration: _dragAt == null
          ? const Duration(milliseconds: 260)
          : Duration.zero,
      curve: Curves.easeOutCubic,
      left: at.dx,
      top: at.dy,
      width: size.width,
      height: size.height,
      child: GestureDetector(
        onTap: widget.onExpand,
        onPanStart: (_) => setState(() => _dragAt = at),
        onPanUpdate: (d) => setState(() => _dragAt = _dragAt! + d.delta),
        onPanEnd: (d) => _release(d.velocity, size, screen),
        child: widget.state.audioOnly
            ? MiniVideoAudioCard(state: widget.state, onClose: widget.onClose)
            : MiniVideoCard(state: widget.state, onClose: widget.onClose),
      ),
    );
  }

  /// Snaps to the nearest corner, or closes when thrown off the side.
  void _release(Velocity velocity, Size size, Size screen) {
    final at = _dragAt!;
    final center = at + size.center(Offset.zero);
    final vx = velocity.pixelsPerSecond.dx;
    final halfOut =
        at.dx < -size.width / 2 || at.dx + size.width / 2 > screen.width;
    final thrownOut =
        (vx < -1500 && center.dx < screen.width / 3) ||
        (vx > 1500 && center.dx > screen.width * 2 / 3);
    if (halfOut || thrownOut) {
      setState(() => _dragAt = null);
      widget.onClose();
      return;
    }
    setState(() {
      _corner = Alignment(
        center.dx < screen.width / 2 ? -1 : 1,
        center.dy < screen.height / 2 ? -1 : 1,
      );
      _dragAt = null;
    });
  }

  /// About 45% of the screen's width (at most 240), in the video's shape
  /// (between 16:9 wide and 9:16 tall).
  ///
  /// As audio: a slim card, about 70% of the width (at most 320).
  Size _windowSize(Size screen) {
    if (widget.state.audioOnly) {
      return Size(
        (screen.shortestSide * 0.72).clamp(240.0, 320.0),
        MiniVideoAudioCard.height,
      );
    }
    final width = (screen.shortestSide * 0.46).clamp(140.0, 240.0);
    final engine = widget.state.engine;
    final video = widget.state.video;
    final aspect = engine != null && engine.value.isInitialized
        ? engine.value.aspectRatio
        : (video.width > 0 && video.height > 0
              ? video.width / video.height
              : 16 / 9);
    return Size(width, width / aspect.clamp(9 / 16, 16 / 9));
  }
}
