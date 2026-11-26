import 'package:melodix/core/models/load_status.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/utils/debug_counters.dart';
import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/domain/entities/artist.dart';
import 'package:melodix/features/music_library/domain/entities/library_changes.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/usecases/build_library_catalog_usecase.dart';

class LibraryCollectionsState extends Equatable {
  const LibraryCollectionsState({
    this.status = LoadStatus.loading,
    this.albums = const [],
    this.artists = const [],
  });

  final LoadStatus status;
  final List<Album> albums;
  final List<Artist> artists;

  @override
  List<Object?> get props => [status, albums, artists];
}

/// Albums and artists for the Music home tabs, built from the library's
/// songs already in memory (no database reads).
class LibraryCollectionsCubit extends Cubit<LibraryCollectionsState> {
  LibraryCollectionsCubit({required this._buildCatalog})
    : super(const LibraryCollectionsState());

  final BuildLibraryCatalogUseCase _buildCatalog;

  /// The songs the current albums / artists were built from.
  List<Song>? _builtFrom;

  /// Call with the library's songs whenever they change. Albums and artists
  /// are rebuilt only when songs were added, removed or had their grouping
  /// fields changed; favourite or play-count changes don't regroup.
  Future<void> onLibraryChanged(List<Song> songs) async {
    final previous = _builtFrom;
    _builtFrom = songs;
    if (previous != null && !catalogChanged(previous, songs)) return;
    if (isClosed) return;
    // ignore: invalid_use_of_visible_for_testing_member
    DebugCounters.hit('collectionsRebuild');
    final catalog = _buildCatalog(songs);
    emit(
      LibraryCollectionsState(
        status: LoadStatus.ready,
        albums: catalog.albums,
        artists: catalog.artists,
      ),
    );
  }
}
