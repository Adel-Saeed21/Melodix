import 'package:melodix/features/video/presentation/widgets/video_row_actions.dart';
import 'package:melodix/core/models/load_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/widgets/whole_pixel_height.dart';
import 'package:melodix/core/widgets/library_status_view.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/presentation/logic/favorite_videos_cubit.dart';
import 'package:melodix/features/video/presentation/navigation/video_player_navigation.dart';
import 'package:melodix/features/video/presentation/widgets/video_tile.dart';

class FavouriteVideosTab extends StatelessWidget {
  const FavouriteVideosTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoriteVideosCubit, FavoriteVideosState>(
      builder: (context, state) {
        final overlap = SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        );
        final Widget content;
        if (state.status == LoadStatus.loading && state.videos.isEmpty) {
          content = const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (state.videos.isEmpty) {
          content = SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: state.status == LoadStatus.failure
                  ? LibraryStatusView(
                      icon: Icons.error_outline_rounded,
                      title: AppStrings.libraryErrorTitle,
                      message: state.errorMessage ?? '',
                    )
                  : const LibraryStatusView(
                      icon: Icons.favorite_border_rounded,
                      title: AppStrings.noFavouriteVideosTitle,
                      message: AppStrings.noFavouriteVideosSubtitle,
                    ),
            ),
          );
        } else {
          // Fixed-height rows (measured once), like the song lists.
          content = SliverPrototypeExtentList.builder(
            prototypeItem: _row(context, state.videos, 0),
            itemCount: state.videos.length,
            itemBuilder: (_, index) => _row(context, state.videos, index),
          );
        }
        return CustomScrollView(
          key: const PageStorageKey('favourite-videos'),
          slivers: [
            overlap,
            SliverPadding(padding: EdgeInsets.only(top: 8.h)),
            content,
            SliverPadding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 16.h,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _row(BuildContext context, List<Video> videos, int index) {
    final video = videos[index];
    return WholePixelHeight(
      child: VideoTile(
        key: ValueKey(video.id),
        video: video,
        // Next / previous in the player move through the favourites.
        onTap: () => openVideoPlayer(context, videos, index),
        trailing: VideoRowActions(video: video),
      ),
    );
  }
}
