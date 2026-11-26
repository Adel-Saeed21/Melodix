import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/routing/routes.dart';
import 'package:melodix/core/service/navigation_extension.dart';
import 'package:melodix/features/video/domain/entities/video.dart';

/// What the player opens: a list of videos and the one to start with.
class VideoPlayerArgs {
  const VideoPlayerArgs(this.videos, this.index);

  final List<Video> videos;
  final int index;
}

/// Opens the player on [videos], starting at [index].
void openVideoPlayer(BuildContext context, List<Video> videos, int index) {
  context.pushNamed(Routes.videoPlayer, extra: VideoPlayerArgs(videos, index));
}
