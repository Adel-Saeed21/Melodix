import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/features/music_library/domain/entities/library_search_results.dart';
import 'package:melodix/features/music_library/domain/usecases/search_library_usecase.dart';

class LibrarySearchState extends Equatable {
  const LibrarySearchState({
    this.query = '',
    this.isLoading = false,
    this.results = LibrarySearchResults.empty,
    this.errorMessage,
  });

  /// The trimmed text being searched.
  final String query;
  final bool isLoading;

  /// Results for [query] (empty while there's no query).
  final LibrarySearchResults results;
  final String? errorMessage;

  bool get hasQuery => query.isNotEmpty;

  @override
  List<Object?> get props => [query, isLoading, results, errorMessage];
}

/// Searches the library as the user types. Typing is debounced, and results
/// for an older query that arrive late are ignored.
class LibrarySearchCubit extends Cubit<LibrarySearchState> {
  LibrarySearchCubit({
    required this._search,
    this.debounce = const Duration(milliseconds: 250),
  }) : super(const LibrarySearchState());

  final SearchLibraryUseCase _search;
  final Duration debounce;

  Timer? _debounceTimer;
  int _requestId = 0;

  void queryChanged(String text) {
    final query = text.trim();
    _debounceTimer?.cancel();
    if (query.isEmpty) {
      _requestId++; // drop any search still in flight
      emit(const LibrarySearchState());
      return;
    }
    if (query == state.query && !state.isLoading) return;
    emit(
      LibrarySearchState(query: query, isLoading: true, results: state.results),
    );
    _debounceTimer = Timer(debounce, () => _run(query));
  }

  /// Re-runs the current search, e.g. after the library changed.
  Future<void> refresh() async {
    if (state.hasQuery) await _run(state.query);
  }

  void clear() => queryChanged('');

  Future<void> _run(String query) async {
    final id = ++_requestId;
    final result = await _search(query);
    if (isClosed || id != _requestId) return; // a newer search replaced it
    emit(
      result.fold(
        (failure) =>
            LibrarySearchState(query: query, errorMessage: failure.message),
        (results) => LibrarySearchState(query: query, results: results),
      ),
    );
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
