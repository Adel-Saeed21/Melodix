import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/presentation/widgets/library/video_favourite_button.dart';
import 'package:melodix/features/video/presentation/widgets/video_options_button.dart';

/// The end of a video row: ♥ and the ⋮ menu (play next, add to queue,
/// delete). The same wherever videos are listed.
class VideoRowActions extends StatelessWidget {
  const VideoRowActions({super.key, required this.video});

  final Video video;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        VideoFavouriteButton(video: video),
        VideoOptionsButton(video: video),
      ],
    );
  }
}
