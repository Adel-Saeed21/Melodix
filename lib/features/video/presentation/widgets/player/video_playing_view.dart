import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/video/presentation/widgets/player/subtitle_overlay.dart';
import 'package:melodix/features/video/presentation/playback/video_engine.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_player_controls.dart';

/// The video, with its subtitles and the controls over it. The picture fits the screen
/// (whole, with bars) or fills it (zoomed, cropped): the user's choice.
class VideoPlayingView extends StatefulWidget {
  const VideoPlayingView({
    super.key,
    required this.engine,
    required this.onRotate,
  });

  final VideoEngine engine;
  final VoidCallback onRotate;

  @override
  State<VideoPlayingView> createState() => _VideoPlayingViewState();
}

class _VideoPlayingViewState extends State<VideoPlayingView> {
  bool _fill = false;

  @override
  Widget build(BuildContext context) {
    final engine = widget.engine;
    final size = engine.value.size;
    return Stack(
      fit: StackFit.expand,
      children: [
        // The picture in its own layer: controls fading in and out never
        // repaint it.
        RepaintBoundary(
          child: _fill && !size.isEmpty
              ? ClipRect(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox.fromSize(
                      size: size,
                      child: engine.buildView(),
                    ),
                  ),
                )
              : Center(
                  child: AspectRatio(
                    aspectRatio: engine.value.aspectRatio,
                    child: engine.buildView(),
                  ),
                ),
        ),
        // The caption showing now (when subtitles are on).
        SubtitleOverlay(engine: engine),
        VideoPlayerControls(
          engine: engine,
          onRotate: widget.onRotate,
          fill: _fill,
          onToggleFill: () => setState(() => _fill = !_fill),
        ),
      ],
    );
  }
}
