import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/widgets/whole_pixel_height.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/presentation/logic/video_library_cubit.dart';
import 'package:melodix/features/video/presentation/navigation/video_player_navigation.dart';
import 'package:melodix/features/video/presentation/widgets/library/continue_watching_row.dart';
import 'package:melodix/features/video/presentation/widgets/library/video_favourite_button.dart';
import 'package:melodix/features/video/presentation/widgets/library/video_section_title.dart';
import 'package:melodix/features/video/presentation/widgets/video_tile.dart';

/// Continue watching (if any) above every video, in fixed-height rows.
class VideoLibraryList extends StatelessWidget {
  const VideoLibraryList({super.key, required this.state});

  final VideoLibraryState state;

  @override
  Widget build(BuildContext context) {
    final videos = state.videos;
    final resume = state.continueWatching;
    return CustomScrollView(
      key: const PageStorageKey('videos'),
      slivers: [
        if (resume.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: ContinueWatchingRow(
              videos: resume,
              onOpen: (list, index) => openVideoPlayer(context, list, index),
            ),
          ),
          SliverToBoxAdapter(child: VideoSectionTitle(AppStrings.allVideos)),
        ] else
          SliverPadding(padding: EdgeInsets.only(top: 4.h)),
        // Fixed-height rows (measured once): thousands of videos scroll
        // and jump without laying out the ones skipped.
        SliverPrototypeExtentList.builder(
          prototypeItem: _row(context, videos, 0),
          itemCount: videos.length,
          itemBuilder: (context, index) => _row(context, videos, index),
        ),
        SliverPadding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + 16.h,
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, List<Video> videos, int index) {
    final video = videos[index];
    return WholePixelHeight(
      child: VideoTile(
        key: ValueKey(video.id),
        video: video,
        onTap: () => openVideoPlayer(context, videos, index),
        trailing: VideoFavouriteButton(video: video),
      ),
    );
  }
}
