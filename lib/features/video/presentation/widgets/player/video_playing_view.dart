import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/video/presentation/widgets/player/keep_screen_on.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_player_controls.dart';
import 'package:video_player/video_player.dart';

class VideoPlayingView extends StatelessWidget {
  const VideoPlayingView({
    super.key,
    required this.controller,
    required this.onRotate,
  });

  final VideoPlayerController controller;
  final VoidCallback onRotate;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // The picture in its own layer: controls fading in and out never
        // repaint it.
        RepaintBoundary(
          child: Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
        ),
        KeepScreenOn(controller: controller),
        VideoPlayerControls(controller: controller, onRotate: onRotate),
      ],
    );
  }
}
