import 'package:melodix/core/widgets/selection/selection_actions_overlay.dart';
import 'package:melodix/core/widgets/app_snack_bar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/widgets/whole_pixel_height.dart';
import 'package:melodix/core/utils/debug_counters.dart';
import 'package:melodix/features/music_library/domain/entities/library_changes.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/entities/song_sort_order.dart';
import 'package:melodix/features/music_library/presentation/logic/song_actions_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/song_selection_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/song_sort_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/add_to_playlist_sheet.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_options_button.dart';
import 'package:melodix/core/widgets/selection/selection_widgets.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_selection_widgets.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_sort_button.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_tile.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';

/// The songs list with sorting and multi-select: hold a song (or tap the
/// ☑ icon) to select songs, then act on them from the floating bar.
class SongsTabBody extends StatefulWidget {
  const SongsTabBody({super.key, required this.songs});

  final List<Song> songs;

  @override
  State<SongsTabBody> createState() => _SongsTabBodyState();
}

class _SongsTabBodyState extends State<SongsTabBody> {
  static const Duration _animation = Duration(milliseconds: 250);

  List<Song> get songs => widget.songs;

  // The sorted list, reused until the songs or the order change (selecting
  // songs, for example, no longer re-sorts the library).
  List<Song> _sorted = const [];
  List<Song>? _sortedFrom;
  SongSortOrder? _sortedBy;

  /// Where each song sits in [_sorted] (rebuilt only when it changes), so
  /// the selection's songs are found without scanning the whole library on
  /// every tap.
  Map<int, int> _positionOf = const {};
  List<Song>? _positionsFor;

  /// The selected songs still in the library, in list order.
  List<Song> _selectedSongs(List<Song> sorted, SongSelectionState selection) {
    if (!selection.active || selection.ids.isEmpty) return const [];
    if (!identical(_positionsFor, sorted)) {
      _positionOf = {for (var i = 0; i < sorted.length; i++) sorted[i].id: i};
      _positionsFor = sorted;
    }
    final positions = [for (final id in selection.ids) ?_positionOf[id]]
      ..sort();
    return [for (final i in positions) sorted[i]];
  }

  List<Song> _sortedSongs(SongSortOrder order) {
    final previous = _sortedFrom;
    if (identical(previous, songs) && _sortedBy == order) return _sorted;
    if (previous != null &&
        _sortedBy == order &&
        !sortKeysChanged(previous, songs, order)) {
      // Nothing the order depends on changed (e.g. a favourite): keep the
      // order and swap in the updated songs. O(n), no sort.
      final byId = {for (final song in songs) song.id: song};
      _sorted = [for (final song in _sorted) byId[song.id]!];
    } else {
      // ignore: invalid_use_of_visible_for_testing_member
      DebugCounters.hit('songsSort');
      _sorted = sortSongs(songs, order);
    }
    _sortedFrom = songs;
    _sortedBy = order;
    return _sorted;
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<SongSortCubit>().state;
    final selection = context.watch<SongSelectionCubit>().state;
    final sorted = _sortedSongs(order);
    // Only songs still in the library count (some may have been removed).
    final selectedSongs = _selectedSongs(sorted, selection);

    return PopScope(
      // Back leaves selection mode first.
      canPop: !selection.active,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.read<SongSelectionCubit>().exit();
      },
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.only(top: 8.h),
                sliver: SliverToBoxAdapter(
                  child: _topRow(
                    context,
                    order,
                    selection,
                    sorted,
                    selectedSongs,
                  ),
                ),
              ),
              if (sorted.isNotEmpty)
                // Every row as tall as a real row in the current mode
                // (measured once): placing row 5,000 is a sum, so long
                // jumps and fast flings never lay out the rows they skip.
                SliverPrototypeExtentList.builder(
                  prototypeItem: _row(context, sorted, 0, order, selection),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) =>
                      _row(context, sorted, index, order, selection),
                ),
              SliverPadding(
                // Leave room for the action bar while selecting.
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
            enabled: selectedSongs.isNotEmpty,
            actions: _actions(context, selectedSongs),
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
              padding: EdgeInsetsDirectional.fromSTEB(8.w, 0, 12.w, 0),
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
              padding: EdgeInsetsDirectional.fromSTEB(20.w, 0, 8.w, 0),
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
                    tooltip: context.l10n.selectSongs,
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
          ? '${song.artist} · ${context.l10n.playsCount(song.playCount)}'
          : null,
      leading: selection.active ? SelectionCheck(selected: selected) : null,
      trailing: selection.active ? null : SongOptionsButton(song: song),
      // Selecting: toggle. Otherwise play this list from the tapped song.
      onTap: selection.active
          ? () => selectionCubit.toggle(song.id)
          : () => context.read<PlayerCubit>().playSongs(
              sorted,
              index,
              title: context.l10n.songs,
            ),
      onLongPress: () {
        HapticFeedback.selectionClick();
        selection.active
            ? selectionCubit.toggle(song.id)
            : selectionCubit.start(song.id);
      },
    );
    return WholePixelHeight(
      child: AnimatedContainer(
        duration: _animation,
        color: selected
            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
            : Colors.transparent,
        child: tile,
      ),
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
        icon: Icons.queue_music_rounded,
        label: context.l10n.queueShort,
        onTap: () async {
          final messages = AppSnackBarTarget.of(context);
          final l10n = context.l10n;
          await context.read<PlayerCubit>().addToQueue(selected);
          selection.exit();
          messages.show(l10n.addedToQueue(selected.length));
        },
      ),
      BulkAction(
        icon: Icons.playlist_add_rounded,
        label: context.l10n.playlistShort,
        onTap: () => run(
          () =>
              showAddToPlaylistSheet(context, songs: selected, cubit: actions),
        ),
      ),
      BulkAction(
        icon: allFavourite
            ? Icons.heart_broken_rounded
            : Icons.favorite_border_rounded,
        label: allFavourite ? context.l10n.unfavourite : context.l10n.favourite,
        onTap: () => run(() => actions.favoriteMany(selected)),
      ),
      if (actions.canDeleteSongs)
        BulkAction(
          icon: Icons.delete_outline_rounded,
          label: context.l10n.delete,
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
