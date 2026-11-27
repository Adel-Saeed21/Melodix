import 'package:melodix/core/models/load_status.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/widgets/whole_pixel_height.dart';
import 'package:melodix/core/widgets/app_snack_bar.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/presentation/logic/song_list_cubit.dart';
import 'package:melodix/core/widgets/library_status_view.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_actions_scope.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_options_button.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_tile.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_list_body/song_drag_handle.dart';

/// A header followed by the songs from the nearest [SongListCubit], each
/// with its ⋮ options menu. The header is built from the songs shown, so
/// counts and durations always match the list.
///
/// If the cubit can save an order ([SongListCubit.canReorder]), songs can be
/// moved by long-pressing a row (or dragging its handle).
class SongListBody extends StatelessWidget {
  const SongListBody({
    super.key,
    required this.header,
    this.subtitleFor,
    this.showGoToAlbum = true,
    this.showGoToArtist = true,
    this.playlist,
    this.emptyView,
    this.queueTitle,
    this.insideNestedScrollView = false,
  });

  final Widget Function(List<Song> songs) header;

  /// Custom subtitle per song (defaults to the artist).
  final String Function(Song song)? subtitleFor;

  /// Passed to each song's ⋮ menu.
  final bool showGoToAlbum;
  final bool showGoToArtist;

  /// On a playlist's page: lets each song be removed from it.
  final Playlist? playlist;

  /// Shown under the header when there are no songs.
  final Widget? emptyView;

  /// Names this list in the player's queue (e.g. the album title).
  final String? queueTitle;

  /// In a [NestedScrollView] body whose pinned header is wrapped in a
  /// [SliverOverlapAbsorber]: starts below that header instead of under
  /// it. Only for lists that can't be reordered.
  final bool insideNestedScrollView;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SongListCubit>();
    return SongActionsScope(
      // A list that isn't live is reloaded after favouriting / hiding.
      onAction: cubit.isLive ? null : cubit.load,
      child: BlocConsumer<SongListCubit, SongListState>(
        listenWhen: (p, c) => c.reorderFailures > p.reorderFailures,
        listener: (context, _) => AppSnackBar.show(
          context,
          AppStrings.reorderFailed,
          kind: AppSnackBarKind.error,
        ),
        builder: (context, state) {
          if (state.status == LoadStatus.loading && state.songs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == LoadStatus.failure && state.songs.isEmpty) {
            return LibraryStatusView(
              icon: Icons.error_outline_rounded,
              title: AppStrings.libraryErrorTitle,
              message: state.errorMessage ?? '',
              actionLabel: AppStrings.tryAgain,
              onAction: cubit.load,
            );
          }
          final header = this.header(state.songs);
          final bottomPadding = EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + 16.h,
          );

          assert(!insideNestedScrollView || !cubit.canReorder);
          if (state.songs.isEmpty || !cubit.canReorder) {
            return CustomScrollView(
              key: insideNestedScrollView
                  ? const PageStorageKey('song-list')
                  : null,
              slivers: [
                if (insideNestedScrollView)
                  SliverOverlapInjector(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                      context,
                    ),
                  ),
                SliverToBoxAdapter(child: header),
                if (state.songs.isEmpty)
                  ?(emptyView == null
                      ? null
                      : SliverToBoxAdapter(child: emptyView))
                else
                  // Every row as tall as a real one (measured once): long
                  // lists never lay out the rows they skip.
                  SliverPrototypeExtentList.builder(
                    prototypeItem: _tile(context, state.songs, 0),
                    itemCount: state.songs.length,
                    itemBuilder: (context, index) =>
                        _tile(context, state.songs, index),
                  ),
                SliverPadding(padding: bottomPadding),
              ],
            );
          }

          return ReorderableListView.builder(
            header: header,
            padding: bottomPadding,
            buildDefaultDragHandles: false,
            itemCount: state.songs.length,
            // Same fixed row height as the plain list (with the handle).
            prototypeItem: _tile(context, state.songs, 0, dragIndex: 0),
            onReorderStart: (_) => HapticFeedback.mediumImpact(),
            onReorderItem: cubit.reorder,
            proxyDecorator: _liftedRow,
            itemBuilder: (context, index) {
              final song = state.songs[index];
              return ReorderableDelayedDragStartListener(
                key: ValueKey(song.id),
                index: index,
                child: _tile(context, state.songs, index, dragIndex: index),
              );
            },
          );
        },
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    List<Song> songs,
    int index, {
    int? dragIndex,
  }) {
    final song = songs[index];
    return WholePixelHeight(
      child: SongTile(
        song: song,
        // Play this list (album / artist / playlist) from the tapped song.
        onTap: () => context.read<PlayerCubit>().playSongs(
          songs,
          index,
          title: queueTitle,
        ),
        subtitle: subtitleFor?.call(song),
        leading: dragIndex == null ? null : SongDragHandle(index: dragIndex),
        trailing: SongOptionsButton(
          song: song,
          showGoToAlbum: showGoToAlbum,
          showGoToArtist: showGoToArtist,
          playlist: playlist,
        ),
      ),
    );
  }

  /// The row being dragged: lifted with a soft shadow and rounded corners.
  static Widget _liftedRow(Widget child, int index, Animation<double> anim) {
    return AnimatedBuilder(
      animation: anim,
      child: child,
      builder: (context, child) {
        final t = Curves.easeOut.transform(anim.value);
        final theme = Theme.of(context);
        return Transform.scale(
          scale: 1 + 0.02 * t,
          child: Material(
            color: Color.lerp(
              theme.scaffoldBackgroundColor,
              theme.colorScheme.surfaceContainerHigh,
              t,
            ),
            elevation: 8 * t,
            shadowColor: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16.r),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        );
      },
    );
  }
}
