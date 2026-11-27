import 'package:melodix/features/video/domain/entities/video_progress.dart';
import 'package:melodix/core/utils/debug_counters.dart';
import 'package:melodix/core/widgets/selection/selection_actions_overlay.dart';
import 'package:melodix/features/video/presentation/widgets/video_row_actions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/widgets/selection/selection_cubit.dart';
import 'package:melodix/core/widgets/selection/selection_widgets.dart';
import 'package:melodix/core/widgets/whole_pixel_height.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/presentation/logic/favorite_videos_cubit.dart';
import 'package:melodix/features/video/presentation/logic/video_library_cubit.dart';
import 'package:melodix/features/video/presentation/navigation/video_player_navigation.dart';
import 'package:melodix/features/video/presentation/widgets/library/continue_watching_row.dart';
import 'package:melodix/features/video/presentation/widgets/library/video_selection_actions.dart';
import 'package:melodix/features/video/presentation/widgets/video_tile.dart';

/// Continue watching (if any) above every video, in fixed-height rows.
///
/// Videos can be selected like songs: long-press one (or the select icon),
/// tap more, then play, (un)favourite or delete them from the bar below.
class VideoLibraryList extends StatelessWidget {
  const VideoLibraryList({super.key, required this.state});

  final VideoLibraryState state;

  static const Duration _animation = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    // ignore: invalid_use_of_visible_for_testing_member
    DebugCounters.hit('videoListBuild');
    final videos = state.videos;
    final selection = context.watch<SelectionCubit<String>>().state;
    // Only videos still in the library count (some may have been removed).
    final selected = [
      for (final v in videos)
        if (selection.isSelected(v.id)) v,
    ];
    final favouriteIds = context.select((FavoriteVideosCubit c) => c.state.ids);

    return PopScope(
      // Back leaves selection mode first.
      canPop: !selection.active,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.read<SelectionCubit<String>>().exit();
      },
      child: Stack(
        children: [
          CustomScrollView(
            key: const PageStorageKey('videos'),
            slivers: [
              // Follows progress on its own (not the whole list).
              SliverToBoxAdapter(
                child: BlocBuilder<VideoLibraryCubit, VideoLibraryState>(
                  buildWhen: (p, c) =>
                      p.continueWatching != c.continueWatching ||
                      p.progress != c.progress,
                  builder: (context, library) =>
                      library.continueWatching.isEmpty || selection.active
                      ? const SizedBox.shrink()
                      : ContinueWatchingRow(
                          videos: library.continueWatching,
                          progress: library.progress,
                          onOpen: (list, index) =>
                              openVideoPlayer(context, list, index),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: _topRow(context, videos, selected, selection),
              ),
              // Fixed-height rows (measured once): thousands of videos
              // scroll and jump without laying out the ones skipped.
              SliverPrototypeExtentList.builder(
                prototypeItem: _row(context, videos, 0, selection),
                itemCount: videos.length,
                itemBuilder: (context, index) =>
                    _row(context, videos, index, selection),
              ),
              SliverPadding(
                // Room for the action bar while selecting.
                padding: EdgeInsets.only(
                  bottom: SelectionActionsOverlay.listBottomPadding(
                    context,
                    active: selection.active,
                  ),
                ),
              ),
            ],
          ),
          // Where the user chose (Settings): bottom bar or right side.
          SelectionActionsOverlay(
            active: selection.active,
            enabled: selected.isNotEmpty,
            actions: videoSelectionActions(
              context,
              selected,
              allFavourite:
                  selected.isNotEmpty &&
                  selected.every((v) => favouriteIds.contains(v.id)),
            ),
          ),
        ],
      ),
    );
  }

  /// "All videos" with the select icon; while selecting, "3 selected" and
  /// Select all.
  Widget _topRow(
    BuildContext context,
    List<Video> videos,
    List<Video> selected,
    SelectionState<String> selection,
  ) {
    final cubit = context.read<SelectionCubit<String>>();
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return AnimatedSwitcher(
      duration: _animation,
      child: selection.active
          ? Padding(
              key: const ValueKey('selection-header'),
              padding: EdgeInsetsDirectional.fromSTEB(8.w, 8.h, 12.w, 0),
              child: SelectionHeader(
                count: selected.length,
                allSelected:
                    videos.isNotEmpty && selected.length == videos.length,
                onClose: cubit.exit,
                onSelectAll: () => cubit.selectAll(videos.map((v) => v.id)),
                onDeselectAll: cubit.deselectAll,
              ),
            )
          : Padding(
              key: const ValueKey('videos-title'),
              padding: EdgeInsetsDirectional.fromSTEB(20.w, 12.h, 8.w, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.allVideos,
                      style: TextStyle(
                        color: onSurface,
                        fontSize: AppTextSizes.lg,
                        fontWeight: FontWeightHelper.bold,
                      ),
                    ),
                  ),
                  // Tells users videos can be multi-selected.
                  IconButton(
                    tooltip: context.l10n.selectVideos,
                    onPressed: videos.isEmpty ? null : cubit.start,
                    icon: Icon(
                      Icons.checklist_rounded,
                      color: onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _row(
    BuildContext context,
    List<Video> videos,
    int index,
    SelectionState<String> selection,
  ) {
    final video = videos[index];
    final cubit = context.read<SelectionCubit<String>>();
    final selected = selection.isSelected(video.id);
    return WholePixelHeight(
      child: AnimatedContainer(
        duration: _animation,
        color: selected
            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
            : Colors.transparent,
        // Only this row follows its video's progress ("Resume at", bar).
        child:
            BlocSelector<VideoLibraryCubit, VideoLibraryState, VideoProgress?>(
              selector: (library) => library.progress[video.id],
              builder: (context, progress) => VideoTile(
                key: ValueKey(video.id),
                video: video,
                progress: progress,
                leading: selection.active
                    ? SelectionCheck(selected: selected)
                    : null,
                trailing: selection.active
                    ? null
                    : VideoRowActions(video: video),
                // Selecting: toggle. Otherwise play this list from the tapped one.
                onTap: selection.active
                    ? () => cubit.toggle(video.id)
                    : () => openVideoPlayer(context, videos, index),
                onLongPress: () {
                  HapticFeedback.selectionClick();
                  selection.active
                      ? cubit.toggle(video.id)
                      : cubit.start(video.id);
                },
              ),
            ),
      ),
    );
  }
}
