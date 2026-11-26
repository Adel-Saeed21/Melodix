import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/video/presentation/playback/video_engine.dart';

/// All there is in the picture-in-picture window: the video, filling it
/// (Android gives the window the video's shape). Controls would be too
/// small to use; Android adds its own (expand, close).
class PictureInPictureVideo extends StatelessWidget {
  const PictureInPictureVideo({super.key, required this.engine});

  final VideoEngine engine;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: engine.value.aspectRatio,
          child: engine.buildView(),
        ),
      ),
    );
  }
}
