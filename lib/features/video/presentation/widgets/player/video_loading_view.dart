import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/presentation/widgets/video_thumbnail.dart';

/// The thumbnail, dimmed, under a spinner: something to look at at once.
class VideoLoadingView extends StatelessWidget {
  const VideoLoadingView({super.key, required this.video});

  final Video video;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: Opacity(
            opacity: 0.35,
            child: LayoutBuilder(
              builder: (context, constraints) => VideoThumbnail(
                video: video,
                width: constraints.maxWidth,
                showDuration: false,
              ),
            ),
          ),
        ),
        const Center(child: CircularProgressIndicator(color: Colors.white)),
        const SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: BackButton(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
