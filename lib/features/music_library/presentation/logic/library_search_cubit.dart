import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/utils/debug_counters.dart';
import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/domain/entities/artist.dart';
import 'package:melodix/features/music_library/domain/entities/library_search_index.dart';
import 'package:melodix/features/music_library/domain/entities/library_search_results.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';

class LibrarySearchState extends Equatable {
  const LibrarySearchState({
    this.query = '',
    this.isLoading = false,
    this.results = LibrarySearchResults.empty,
  });

  /// The trimmed text being searched.
  final String query;
  final bool isLoading;

  /// Results for [query] (empty while there's no query).
  final LibrarySearchResults results;

  bool get hasQuery => query.isNotEmpty;

  @override
  List<Object?> get props => [query, isLoading, results];
}

/// Searches the library as the user types, over an in-memory
/// [LibrarySearchIndex] kept up to date with [updateSources] (no database
/// reads per search). Typing is debounced.
class LibrarySearchCubit extends Cubit<LibrarySearchState> {
  LibrarySearchCubit({this.debounce = const Duration(milliseconds: 250)})
    : super(const LibrarySearchState());

  final Duration debounce;

  LibrarySearchIndex _index = LibrarySearchIndex.empty;
  Timer? _debounceTimer;

  // Library data received but not indexed yet: indexing waits until a
  // search needs it, so a scan or a library change costs nothing while
  // nobody is searching.
  List<Song>? _songs;
  List<Album>? _albums;
  List<Artist>? _artists;
  List<Playlist>? _playlists;

  /// Feeds the latest library data. An open search updates right away (e.g.
  /// a hidden song disappears, a favourite flag updates); otherwise it's
  /// indexed when the next search runs.
  void updateSources({
    List<Song>? songs,
    List<Album>? albums,
    List<Artist>? artists,
    List<Playlist>? playlists,
  }) {
    _songs = songs ?? _songs;
    _albums = albums ?? _albums;
    _artists = artists ?? _artists;
    _playlists = playlists ?? _playlists;
    if (state.hasQuery && !state.isLoading) _search(state.query);
  }

  /// The index with any pending library data applied.
  LibrarySearchIndex get _upToDateIndex {
    if (_songs != null ||
        _albums != null ||
        _artists != null ||
        _playlists != null) {
      _index = _index.update(
        songs: _songs,
        albums: _albums,
        artists: _artists,
        playlists: _playlists,
      );
      _songs = _albums = _artists = _playlists = null;
    }
    return _index;
  }

  void queryChanged(String text) {
    final query = text.trim();
    _debounceTimer?.cancel();
    if (query.isEmpty) {
      emit(const LibrarySearchState());
      return;
    }
    if (query == state.query && !state.isLoading) return;
    emit(
      LibrarySearchState(query: query, isLoading: true, results: state.results),
    );
    _debounceTimer = Timer(debounce, () => _search(query));
  }

  void clear() => queryChanged('');

  void _search(String query) {
    if (isClosed) return;
    // ignore: invalid_use_of_visible_for_testing_member
    DebugCounters.hit('searchRun');
    emit(
      LibrarySearchState(query: query, results: _upToDateIndex.search(query)),
    );
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
