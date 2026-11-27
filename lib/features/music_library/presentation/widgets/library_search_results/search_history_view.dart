import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/search/search_history.dart';
import 'package:melodix/core/search/search_sources.dart';
import 'package:melodix/core/widgets/library_status_view.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/presentation/logic/library_search_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_search_results/recent_search_row.dart';
import 'package:melodix/features/music_library/presentation/widgets/library_search_results/search_history_header.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_options_button.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_tile.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';

/// What the search shows before anything is typed: the last searches
/// (tap to search again) and what was opened from search (songs here,
/// other kinds from their [SearchSources]). Nothing yet: the usual prompt.
class SearchHistoryView extends StatelessWidget {
  const SearchHistoryView({super.key, required this.onQuery});

  /// A recent search was tapped: search it again.
  final ValueChanged<String> onQuery;

  @override
  Widget build(BuildContext context) {
    final sources = SearchSources.of(context);
    return BlocBuilder<SearchHistoryCubit, SearchHistory>(
      builder: (context, history) {
        final cubit = context.read<SearchHistoryCubit>();
        final opened = _openedRows(context, history, sources);
        if (history.queries.isEmpty && opened.isEmpty) {
          return LibraryStatusView(
            icon: Icons.manage_search_rounded,
            title: context.l10n.searchPromptTitle,
            message: context.l10n.searchPromptSubtitle,
          );
        }
        return ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            top: 4.h,
            bottom: MediaQuery.paddingOf(context).bottom + 16.h,
          ),
          children: [
            if (history.queries.isNotEmpty) ...[
              SearchHistoryHeader(
                title: context.l10n.recentSearches,
                actionLabel: context.l10n.clearSearchHistory,
                onAction: cubit.clearHistory,
              ),
              for (final query in history.queries)
                RecentSearchRow(
                  query: query,
                  onTap: () => onQuery(query),
                  onRemove: () => cubit.removeQuery(query),
                ),
            ],
            if (opened.isNotEmpty) ...[
              SearchHistoryHeader(
                title: context.l10n.openedFromSearch,
                // The one "Clear" sits on the first section shown.
                actionLabel: history.queries.isEmpty
                    ? context.l10n.clearSearchHistory
                    : null,
                onAction: cubit.clearHistory,
              ),
              ...opened,
            ],
          ],
        );
      },
    );
  }

  /// One row per item opened from search that still exists, newest first.
  static List<Widget> _openedRows(
    BuildContext context,
    SearchHistory history,
    List<SearchSource> sources,
  ) {
    final songIds = [
      for (final item in history.opened)
        if (item.kind == OpenedFromSearch.songKind) ?int.tryParse(item.id),
    ];
    final songs = context.read<LibrarySearchCubit>().songsWithIds(songIds);
    final songById = {for (final s in songs) s.id: s};
    final rows = <Widget>[];
    for (final item in history.opened) {
      final Widget? row = item.kind == OpenedFromSearch.songKind
          ? switch (songById[int.tryParse(item.id)]) {
              final Song song => _songRow(context, song, songs),
              null => null, // no longer in the library
            }
          : _sourceFor(sources, item.kind)?.openedTile(context, item.id);
      if (row != null) rows.add(row);
    }
    return rows;
  }

  static SearchSource? _sourceFor(List<SearchSource> sources, String kind) {
    for (final source in sources) {
      if (source.openedKind == kind) return source;
    }
    return null;
  }

  /// A song opened from search: plays the opened songs, from this one.
  static Widget _songRow(BuildContext context, Song song, List<Song> songs) =>
      SongTile(
        song: song,
        trailing: SongOptionsButton(song: song),
        onTap: () {
          context.read<SearchHistoryCubit>().opened(
            OpenedFromSearch.song(song.id),
          );
          context.read<PlayerCubit>().playSongs(
            songs,
            songs.indexOf(song),
            title: context.l10n.openedFromSearch,
          );
        },
      );
}
