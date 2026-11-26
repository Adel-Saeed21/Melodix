import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/presentation/logic/library_collections_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/song_list_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_status_view.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_actions_scope.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_options_button.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_tile.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';

/// A header followed by the songs from the nearest [SongListCubit], each
/// with its ⋮ options menu.
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
  });

  final Widget header;

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

  @override
  Widget build(BuildContext context) {
    return SongActionsScope(
      // This list isn't live, so reload it after favouriting / hiding.
      onAction: () => context.read<SongListCubit>().load(),
      child: BlocConsumer<SongListCubit, SongListState>(
        listenWhen: (p, c) => c.reorderFailures > p.reorderFailures,
        listener: (context, _) => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(AppStrings.reorderFailed),
              behavior: SnackBarBehavior.floating,
            ),
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
              onAction: () => context.read<SongListCubit>().load(),
            );
          }
          final cubit = context.read<SongListCubit>();
          final bottomPadding = EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + 16.h,
          );

          if (state.songs.isEmpty || !cubit.canReorder) {
            return ListView.builder(
              padding: bottomPadding,
              itemCount: state.songs.isEmpty && emptyView != null
                  ? 2
                  : state.songs.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return header;
                if (state.songs.isEmpty) return emptyView!;
                return _tile(context, state.songs, index - 1);
              },
            );
          }

          return ReorderableListView.builder(
            header: header,
            padding: bottomPadding,
            buildDefaultDragHandles: false,
            itemCount: state.songs.length,
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
    return SongTile(
      song: song,
      // Play this list (album / artist / playlist) from the tapped song.
      onTap: () => context.read<PlayerCubit>().playSongs(
        songs,
        index,
        title: queueTitle,
      ),
      subtitle: subtitleFor?.call(song),
      leading: dragIndex == null ? null : _DragHandle(index: dragIndex),
      trailing: SongOptionsButton(
        song: song,
        showGoToAlbum: showGoToAlbum,
        showGoToArtist: showGoToArtist,
        playlist: playlist,
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

/// Starts dragging immediately when touched (long-press works anywhere on
/// the row too).
class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return ReorderableDragStartListener(
      index: index,
      child: Tooltip(
        message: AppStrings.dragToReorder,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
          child: Icon(
            Icons.drag_indicator_rounded,
            size: 20.r,
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
