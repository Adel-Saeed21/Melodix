import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/utils/debug_counters.dart';
import 'package:melodix/core/config/routing/routes.dart';
import 'package:melodix/core/service/navigation_extension.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/entities/song_sort_order.dart';
import 'package:melodix/features/music_library/presentation/logic/library_collections_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/playlists_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/song_actions_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/song_selection_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/song_sort_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/album_card.dart';
import 'package:melodix/features/music_library/presentation/widgets/artist_tile.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_status_view.dart';
import 'package:melodix/features/music_library/presentation/widgets/playlist_dialogs.dart';
import 'package:melodix/features/music_library/presentation/widgets/playlist_tile.dart';
import 'package:melodix/features/music_library/presentation/widgets/add_to_playlist_sheet.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_options_button.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_selection_widgets.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_sort_button.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_tile.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';

/// Bottom padding that keeps the last item clear of the floating nav bar.
EdgeInsets _listPadding(BuildContext context) => EdgeInsets.only(
  top: 8.h,
  bottom: MediaQuery.paddingOf(context).bottom + 16.h,
);

class SongsTab extends StatelessWidget {
  const SongsTab({super.key, required this.songs, required this.onRefresh});

  final List<Song> songs;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SongSelectionCubit(),
      child: _SongsTabBody(songs: songs, onRefresh: onRefresh),
    );
  }
}

/// The songs list with sorting and multi-select: hold a song (or tap the
/// ☑ icon) to select songs, then act on them from the floating bar.
class _SongsTabBody extends StatefulWidget {
  const _SongsTabBody({required this.songs, required this.onRefresh});

  final List<Song> songs;
  final RefreshCallback onRefresh;

  @override
  State<_SongsTabBody> createState() => _SongsTabBodyState();
}

class _SongsTabBodyState extends State<_SongsTabBody> {
  static const Duration _animation = Duration(milliseconds: 250);

  List<Song> get songs => widget.songs;
  RefreshCallback get onRefresh => widget.onRefresh;

  // The sorted list, reused until the songs or the order change (selecting
  // songs, for example, no longer re-sorts the library).
  List<Song> _sorted = const [];
  List<Song>? _sortedFrom;
  SongSortOrder? _sortedBy;

  List<Song> _sortedSongs(SongSortOrder order) {
    if (!identical(_sortedFrom, songs) || _sortedBy != order) {
      // ignore: invalid_use_of_visible_for_testing_member
      DebugCounters.hit('songsSort');
      _sorted = sortSongs(songs, order);
      _sortedFrom = songs;
      _sortedBy = order;
    }
    return _sorted;
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<SongSortCubit>().state;
    final selection = context.watch<SongSelectionCubit>().state;
    final sorted = _sortedSongs(order);
    // Only songs still in the library count (some may have been removed).
    final selectedSongs = selection.active
        ? sorted.where((s) => selection.isSelected(s.id)).toList()
        : const <Song>[];
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      // Back leaves selection mode first.
      canPop: !selection.active,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.read<SongSelectionCubit>().exit();
      },
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: onRefresh,
            color: Theme.of(context).primaryColor,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                top: 8.h,
                // Leave room for the action bar while selecting.
                bottom: bottomInset + (selection.active ? 96.h : 16.h),
              ),
              itemCount: sorted.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _topRow(
                    context,
                    order,
                    selection,
                    sorted,
                    selectedSongs,
                  );
                }
                return _row(context, sorted, index - 1, order, selection);
              },
            ),
          ),
          Positioned(
            left: 16.w,
            right: 16.w,
            bottom: bottomInset + 12.h,
            child: IgnorePointer(
              ignoring: !selection.active,
              child: AnimatedSlide(
                duration: _animation,
                curve: Curves.easeOutCubic,
                offset: selection.active ? Offset.zero : const Offset(0, 1.6),
                child: AnimatedOpacity(
                  duration: _animation,
                  opacity: selection.active ? 1 : 0,
                  child: BulkActionBar(
                    enabled: selectedSongs.isNotEmpty,
                    actions: _actions(context, selectedSongs),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topRow(
    BuildContext context,
    SongSortOrder order,
    SongSelectionState selection,
    List<Song> sorted,
    List<Song> selectedSongs,
  ) {
    final selectionCubit = context.read<SongSelectionCubit>();
    return AnimatedSwitcher(
      duration: _animation,
      child: selection.active
          ? Padding(
              key: const ValueKey('selection-header'),
              padding: EdgeInsets.fromLTRB(8.w, 0, 12.w, 0),
              child: SelectionHeader(
                count: selectedSongs.length,
                allSelected:
                    sorted.isNotEmpty && selectedSongs.length == sorted.length,
                onClose: selectionCubit.exit,
                onSelectAll: () =>
                    selectionCubit.selectAll(sorted.map((s) => s.id)),
                onDeselectAll: selectionCubit.deselectAll,
              ),
            )
          : Padding(
              key: const ValueKey('sort-row'),
              padding: EdgeInsets.fromLTRB(20.w, 0, 8.w, 0),
              child: Row(
                children: [
                  // The chip takes the left side; the select icon stays pinned
                  // to the right edge whatever the chip's label length.
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SongSortButton(
                        order: order,
                        onSelected: context.read<SongSortCubit>().select,
                      ),
                    ),
                  ),
                  // Tells users songs can be multi-selected.
                  IconButton(
                    tooltip: AppStrings.selectSongs,
                    onPressed: sorted.isEmpty ? null : selectionCubit.start,
                    icon: Icon(
                      Icons.checklist_rounded,
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _row(
    BuildContext context,
    List<Song> sorted,
    int index,
    SongSortOrder order,
    SongSelectionState selection,
  ) {
    final song = sorted[index];
    final selectionCubit = context.read<SongSelectionCubit>();
    final selected = selection.isSelected(song.id);
    final tile = SongTile(
      song: song,
      // With "Most played", show how often each song was played.
      subtitle: order == SongSortOrder.mostPlayed
          ? '${song.artist} · ${AppStrings.playsCount(song.playCount)}'
          : null,
      leading: selection.active ? SelectionCheck(selected: selected) : null,
      trailing: selection.active ? null : SongOptionsButton(song: song),
      // Selecting: toggle. Otherwise play this list from the tapped song.
      onTap: selection.active
          ? () => selectionCubit.toggle(song.id)
          : () => context.read<PlayerCubit>().playSongs(
              sorted,
              index,
              title: AppStrings.songs,
            ),
      onLongPress: () {
        HapticFeedback.selectionClick();
        selection.active
            ? selectionCubit.toggle(song.id)
            : selectionCubit.start(song.id);
      },
    );
    return AnimatedContainer(
      duration: _animation,
      color: selected
          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
          : Colors.transparent,
      child: tile,
    );
  }

  List<BulkAction> _actions(BuildContext context, List<Song> selected) {
    final actions = context.read<SongActionsCubit>();
    final selection = context.read<SongSelectionCubit>();
    final allFavourite =
        selected.isNotEmpty && selected.every((s) => s.isFavorite);

    Future<void> run(Future<bool> Function() action) async {
      if (await action()) selection.exit();
    }

    return [
      BulkAction(
        icon: Icons.playlist_add_rounded,
        label: AppStrings.playlistShort,
        onTap: () => run(
          () =>
              showAddToPlaylistSheet(context, songs: selected, cubit: actions),
        ),
      ),
      BulkAction(
        icon: allFavourite
            ? Icons.heart_broken_rounded
            : Icons.favorite_border_rounded,
        label: allFavourite ? AppStrings.unfavourite : AppStrings.favourite,
        onTap: () => run(() => actions.favoriteMany(selected)),
      ),
      BulkAction(
        icon: Icons.visibility_off_rounded,
        label: AppStrings.hide,
        onTap: () => run(() => actions.hideMany(selected)),
      ),
      if (actions.canDeleteSongs)
        BulkAction(
          icon: Icons.delete_outline_rounded,
          label: AppStrings.delete,
          destructive: true,
          onTap: () => run(() async {
            if (!await confirmDeleteSongs(context, selected.length)) {
              return false;
            }
            return actions.deleteMany(selected);
          }),
        ),
    ];
  }
}

class AlbumsTab extends StatelessWidget {
  const AlbumsTab({super.key, required this.onRefresh});

  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCollectionsCubit, LibraryCollectionsState>(
      builder: (context, state) {
        if (state.status == LoadStatus.loading && state.albums.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: onRefresh,
          color: Theme.of(context).primaryColor,
          child: state.albums.isEmpty
              ? _ScrollableMessage(
                  icon: Icons.album_rounded,
                  title: AppStrings.noAlbums,
                )
              : GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: _listPadding(context)
                      .add(EdgeInsets.symmetric(horizontal: 20.w)),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.w,
                    mainAxisSpacing: 16.h,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: state.albums.length,
                  itemBuilder: (context, index) {
                    final album = state.albums[index];
                    return AlbumCard(
                      album: album,
                      onTap: () =>
                          context.pushNamed(Routes.albumDetails, extra: album),
                    );
                  },
                ),
        );
      },
    );
  }
}

class ArtistsTab extends StatelessWidget {
  const ArtistsTab({super.key, required this.onRefresh});

  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCollectionsCubit, LibraryCollectionsState>(
      builder: (context, state) {
        if (state.status == LoadStatus.loading && state.artists.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: onRefresh,
          color: Theme.of(context).primaryColor,
          child: state.artists.isEmpty
              ? _ScrollableMessage(
                  icon: Icons.person_rounded,
                  title: AppStrings.noArtists,
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: _listPadding(context),
                  itemCount: state.artists.length,
                  itemBuilder: (context, index) {
                    final artist = state.artists[index];
                    return ArtistTile(
                      artist: artist,
                      onTap: () => context.pushNamed(
                        Routes.artistDetails,
                        extra: artist,
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

/// An empty-state message that still supports pull-to-refresh.
class _ScrollableMessage extends StatelessWidget {
  const _ScrollableMessage({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: LibraryStatusView(
            icon: icon,
            title: title,
            message: AppStrings.noMusicSubtitle,
          ),
        ),
      ),
    );
  }
}

class PlaylistsTab extends StatelessWidget {
  const PlaylistsTab({super.key});

  Future<void> _create(BuildContext context) async {
    final cubit = context.read<PlaylistsCubit>();
    final name = await showPlaylistNameDialog(context);
    if (name != null) await cubit.create(name);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return BlocBuilder<PlaylistsCubit, PlaylistsState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.playlists.isEmpty) {
          return LibraryStatusView(
            icon: Icons.queue_music_rounded,
            title: AppStrings.noPlaylistsYet,
            message: AppStrings.createPlaylistHint,
            actionLabel: AppStrings.newPlaylist,
            onAction: () => _create(context),
          );
        }
        return ListView.builder(
          padding: _listPadding(context),
          itemCount: state.playlists.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20.w),
                leading: Container(
                  width: 52.r,
                  height: 52.r,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(52.r * 0.18),
                  ),
                  child: Icon(Icons.add_rounded, color: primary),
                ),
                title: Text(
                  AppStrings.newPlaylist,
                  style: TextStyle(color: primary, fontWeight: FontWeight.w600),
                ),
                onTap: () => _create(context),
              );
            }
            final playlist = state.playlists[index - 1];
            return PlaylistTile(
              playlist: playlist,
              onTap: () =>
                  context.pushNamed(Routes.playlistDetails, extra: playlist),
            );
          },
        );
      },
    );
  }
}
