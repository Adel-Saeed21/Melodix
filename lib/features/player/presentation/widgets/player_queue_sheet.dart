import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:flutter/rendering.dart';
import 'package:melodix/core/widgets/whole_pixel_height.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_tile.dart';

/// Shows the songs the current one is playing from ("Playing from …"),
/// highlighting the current song. Tapping a song jumps to it.
Future<void> showPlayerQueue(BuildContext context) {
  final cubit = context.read<PlayerCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
    ),
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const _PlayerQueueSheet()),
  );
}

class _PlayerQueueSheet extends StatelessWidget {
  const _PlayerQueueSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) =>
          BlocBuilder<PlayerCubit, NowPlaying>(
            buildWhen: (p, c) =>
                p.queue != c.queue ||
                p.currentIndex != c.currentIndex ||
                p.isPlaying != c.isPlaying ||
                p.queueTitle != c.queueTitle,
            builder: (context, state) =>
                _QueueList(state: state, scrollController: scrollController),
          ),
    );
  }
}

class _QueueList extends StatefulWidget {
  const _QueueList({required this.state, required this.scrollController});

  final NowPlaying state;
  final ScrollController scrollController;

  @override
  State<_QueueList> createState() => _QueueListState();
}

class _QueueListState extends State<_QueueList> {
  /// The song rows (to read their real height and position after layout).
  final GlobalKey _rows = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Start with the current song in view (one row above it showing).
    WidgetsBinding.instance.addPostFrameCallback((_) => _showCurrent());
  }

  /// Jumps straight to the current song. Every row has the same height, so
  /// this is a sum, not a layout of every row before it (in a 10,000-song
  /// queue that used to build thousands of rows to show eight).
  void _showCurrent() {
    final index = widget.state.currentIndex;
    final controller = widget.scrollController;
    final rows = _rows.currentContext?.findRenderObject();
    if (!mounted ||
        index == null ||
        !controller.hasClients ||
        rows is! RenderSliverFixedExtentBoxAdaptor) {
      return;
    }
    final extent = rows.itemExtent;
    if (extent == null) return;
    final header = rows.constraints.precedingScrollExtent;
    final target = header + (index - 1) * extent;
    controller.jumpTo(target.clamp(0.0, controller.position.maxScrollExtent));
  }

  /// The row for the song at [index]; [isCurrent] marks it as playing.
  Widget _row(BuildContext context, int index, {required bool isCurrent}) {
    final primary = Theme.of(context).primaryColor;
    // Whole pixels: the row height is multiplied by the index to place
    // rows, and a fractional height (screen scaling) drifts at row 5,000.
    return WholePixelHeight(
      child: Container(
        color: isCurrent ? primary.withValues(alpha: 0.12) : Colors.transparent,
        child: SongTile(
          song: widget.state.queue[index],
          onTap: () => context.read<PlayerCubit>().playAt(index),
          trailing: isCurrent
              ? Padding(
                  padding: EdgeInsets.only(left: 8.w, right: 16.w),
                  child: Icon(
                    widget.state.isPlaying
                        ? Icons.graphic_eq_rounded
                        : Icons.pause_rounded,
                    color: primary,
                    semanticLabel: AppStrings.nowPlaying,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.primaryColor;
    final state = widget.state;
    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
            child: Row(
              children: [
                Icon(Icons.queue_music_rounded, color: primary),
                horizontalSpace(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.playingFrom,
                        style: TextStyle(
                          color: onSurface.withValues(alpha: 0.6),
                          fontSize: AppTextSizes.sm,
                        ),
                      ),
                      Text(
                        state.queueTitle ?? AppStrings.queue,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: onSurface,
                          fontSize: AppTextSizes.lg,
                          fontWeight: FontWeightHelper.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  AppStrings.songsCount(state.queue.length),
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.6),
                    fontSize: AppTextSizes.sm,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (state.queue.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.only(bottom: 16.h),
            // Every row as tall as the prototype (measured once, at the
            // current text size): jumping anywhere is a sum, and fast
            // scrolling never lays out rows it skips.
            sliver: SliverPrototypeExtentList.builder(
              key: _rows,
              // The current-song row is the tallest kind (it has a mark).
              prototypeItem: _row(context, 0, isCurrent: true),
              itemCount: state.queue.length,
              itemBuilder: (context, index) =>
                  _row(context, index, isCurrent: index == state.currentIndex),
            ),
          ),
      ],
    );
  }
}
