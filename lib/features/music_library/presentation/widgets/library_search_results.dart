import 'dart:math';

import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/routing/routes.dart';
import 'package:melodix/core/search/search_history.dart';
import 'package:melodix/core/search/search_sources.dart';
import 'package:melodix/core/service/navigation_extension.dart';
import 'package:melodix/features/music_library/domain/entities/library_search_results.dart';
import 'package:melodix/features/music_library/presentation/logic/library_search_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/artist_tile.dart';
import 'package:melodix/core/widgets/library_status_view.dart';
import 'package:melodix/features/music_library/presentation/widgets/playlist_tile.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_options_button.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_tile.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_search_results/search_section_header.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_search_results/search_show_all_button.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_search_results/search_album_row.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_search_results/search_history_view.dart';

enum _Section { songs, artists, albums, playlists }

/// Search results grouped into Songs, Artists, Albums and Playlists, then
/// any groups from [SearchSources] above (e.g. Videos). Each group shows a
/// few items with "Show all" to expand. Before anything is typed: the
/// search history ([SearchHistoryView]).
///
/// Opening a result remembers the search (and, for songs and videos, what
/// was opened) in the [SearchHistoryCubit] above.
class LibrarySearchResultsView extends StatefulWidget {
  const LibrarySearchResultsView({super.key, this.onQuery});

  /// A recent search was tapped. Default: it's searched (the screen with
  /// the search field passes its own, to show the text too).
  final ValueChanged<String>? onQuery;

  @override
  State<LibrarySearchResultsView> createState() =>
      _LibrarySearchResultsViewState();
}

class _LibrarySearchResultsViewState extends State<LibrarySearchResultsView> {
  static const _previewCounts = {
    _Section.songs: 5,
    _Section.artists: 3,
    _Section.albums: 3,
    _Section.playlists: 3,
  };

  /// Expanded groups: a [_Section], or an extra group's title.
  final Set<Object> _expanded = {};

  /// How many of an extra group's results show before "Show all".
  static const int _extraPreview = 3;
  String _expandedForQuery = '';

  @override
  Widget build(BuildContext context) {
    final sources = SearchSources.of(context);
    // Extra sources' data changing (e.g. a video added) updates the results.
    return ListenableBuilder(
      listenable: Listenable.merge(sources),
      builder: (context, _) => _results(context, sources),
    );
  }

  Widget _results(BuildContext context, List<SearchSource> sources) {
    return BlocBuilder<LibrarySearchCubit, LibrarySearchState>(
      builder: (context, state) {
        // A new query collapses the groups again.
        if (state.query != _expandedForQuery) {
          _expanded.clear();
          _expandedForQuery = state.query;
        }

        if (!state.hasQuery) {
          return SearchHistoryView(
            onQuery:
                widget.onQuery ??
                context.read<LibrarySearchCubit>().queryChanged,
          );
        }
        final extra = [
          for (final source in sources) ?source.search(state.query),
        ];
        if (state.results.isEmpty && extra.isEmpty) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return LibraryStatusView(
            icon: Icons.search_off_rounded,
            title: AppStrings.noResultsFor(state.query),
            message: AppStrings.noResultsSubtitle,
          );
        }

        final rows = _buildRows(context, state.query, state.results, extra);
        return Stack(
          children: [
            ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                top: 4.h,
                bottom: MediaQuery.paddingOf(context).bottom + 16.h,
              ),
              itemCount: rows.length,
              // Each row is created when it scrolls into view.
              itemBuilder: (_, index) => rows[index](),
            ),
            // Thin bar while newer results load over the current ones.
            if (state.isLoading)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 2),
              ),
          ],
        );
      },
    );
  }

  /// The rows as builders, not widgets: "Show all" on thousands of songs
  /// makes thousands of cheap closures, and only the rows on screen are
  /// ever built.
  List<Widget Function()> _buildRows(
    BuildContext context,
    String query,
    LibrarySearchResults results,
    List<SearchSection> extra,
  ) {
    final rows = <Widget Function()>[];
    final history = context.read<SearchHistoryCubit>();

    void addSection<T>(
      Object section,
      String title,
      List<T> items,
      Widget Function(T item, int index) build, {
      int? previewCount,
    }) {
      if (items.isEmpty) return;
      final preview = previewCount ?? _previewCounts[section]!;
      final expanded = _expanded.contains(section);
      final shown = expanded ? items.length : min(preview, items.length);
      rows.add(() => SearchSectionHeader(title: title, count: items.length));
      for (var i = 0; i < shown; i++) {
        rows.add(() => build(items[i], i));
      }
      if (!expanded && items.length > preview) {
        rows.add(
          () => SearchShowAllButton(
            count: items.length,
            onTap: () => setState(() => _expanded.add(section)),
          ),
        );
      }
    }

    addSection(
      _Section.songs,
      AppStrings.songs,
      results.songs,
      (song, index) => SongTile(
        song: song,
        trailing: SongOptionsButton(song: song),
        // Play the matching songs, starting with this one.
        onTap: () {
          history.opened(OpenedFromSearch.song(song.id), query: query);
          context.read<PlayerCubit>().playSongs(
            results.songs,
            index,
            title: AppStrings.searchResults,
          );
        },
      ),
    );
    addSection(
      _Section.artists,
      AppStrings.artists,
      results.artists,
      (artist, _) => ArtistTile(
        artist: artist,
        onTap: () {
          history.searched(query);
          context.pushNamed(Routes.artistDetails, extra: artist);
        },
      ),
    );
    addSection(
      _Section.albums,
      AppStrings.albums,
      results.albums,
      (album, _) => SearchAlbumRow(
        album: album,
        onTap: () {
          history.searched(query);
          context.pushNamed(Routes.albumDetails, extra: album);
        },
      ),
    );
    addSection(
      _Section.playlists,
      AppStrings.playlists,
      results.playlists,
      (playlist, _) => PlaylistTile(
        playlist: playlist,
        onTap: () {
          history.searched(query);
          context.pushNamed(Routes.playlistDetails, extra: playlist);
        },
      ),
    );
    for (final section in extra) {
      addSection(
        'extra:${section.title}',
        section.title,
        List<int>.generate(section.count, (i) => i),
        (index, _) => section.itemBuilder(context, index),
        previewCount: _extraPreview,
      );
    }
    return rows;
  }
}
