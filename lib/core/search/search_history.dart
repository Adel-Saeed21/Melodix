import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

/// Something opened from the search results: a song, or an item of another
/// [kind] (e.g. a video, see `SearchSource.openedKind`).
class OpenedFromSearch extends Equatable {
  const OpenedFromSearch({required this.kind, required this.id});

  const OpenedFromSearch.song(int songId) : kind = songKind, id = '$songId';

  /// [kind] of songs (the music library's own results).
  static const String songKind = 'song';

  final String kind;
  final String id;

  @override
  List<Object?> get props => [kind, id];
}

/// What the empty search shows: the last searches and what was opened from
/// the results, newest first.
class SearchHistory extends Equatable {
  const SearchHistory({this.queries = const [], this.opened = const []});

  static const empty = SearchHistory();

  /// At most [SearchHistoryCubit.maxQueries].
  final List<String> queries;

  /// At most [SearchHistoryCubit.maxOpened].
  final List<OpenedFromSearch> opened;

  bool get isEmpty => queries.isEmpty && opened.isEmpty;

  @override
  List<Object?> get props => [queries, opened];
}

/// The search history, saved across restarts.
///
/// A search is remembered when it was used (a result opened, or the
/// keyboard's search key), not for every letter typed, so half-typed
/// queries never fill it.
class SearchHistoryCubit extends HydratedCubit<SearchHistory> {
  SearchHistoryCubit() : super(SearchHistory.empty);

  static const int maxQueries = 3;
  static const int maxOpened = 10;

  /// [query] was searched: it goes first (once, whatever its case).
  void searched(String query) {
    final text = query.trim();
    if (text.isEmpty) return;
    final key = text.toLowerCase();
    emit(
      SearchHistory(
        queries: List.unmodifiable(
          [
            text,
            ...state.queries.where((q) => q.toLowerCase() != key),
          ].take(maxQueries),
        ),
        opened: state.opened,
      ),
    );
  }

  /// [item] was opened from the results of [query] (null: opened from the
  /// history itself). It goes first.
  void opened(OpenedFromSearch item, {String? query}) {
    if (query != null) searched(query);
    emit(
      SearchHistory(
        queries: state.queries,
        opened: List.unmodifiable(
          [item, ...state.opened.where((o) => o != item)].take(maxOpened),
        ),
      ),
    );
  }

  void removeQuery(String query) => emit(
    SearchHistory(
      queries: List.unmodifiable(state.queries.where((q) => q != query)),
      opened: state.opened,
    ),
  );

  /// Forgets every search and opened item.
  void clearHistory() => emit(SearchHistory.empty);

  @override
  SearchHistory? fromJson(Map<String, dynamic> json) {
    final queries = json['queries'];
    final opened = json['opened'];
    return SearchHistory(
      queries: queries is List
          ? List.unmodifiable(queries.whereType<String>().take(maxQueries))
          : const [],
      opened: opened is List
          ? List.unmodifiable(
              [
                for (final o in opened)
                  if (o is Map && o['kind'] is String && o['id'] is String)
                    OpenedFromSearch(
                      kind: o['kind'] as String,
                      id: o['id'] as String,
                    ),
              ].take(maxOpened),
            )
          : const [],
    );
  }

  @override
  Map<String, dynamic>? toJson(SearchHistory state) => {
    'queries': state.queries,
    'opened': [
      for (final o in state.opened) {'kind': o.kind, 'id': o.id},
    ],
  };
}
