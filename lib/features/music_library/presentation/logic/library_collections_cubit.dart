import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/domain/entities/artist.dart';
import 'package:melodix/features/music_library/domain/usecases/get_albums_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_artists_usecase.dart';

enum LoadStatus { loading, ready, failure }

class LibraryCollectionsState extends Equatable {
  const LibraryCollectionsState({
    this.status = LoadStatus.loading,
    this.albums = const [],
    this.artists = const [],
    this.errorMessage,
  });

  final LoadStatus status;
  final List<Album> albums;
  final List<Artist> artists;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, albums, artists, errorMessage];
}

/// Albums and artists for the Music home tabs. Call [load] again whenever
/// the library changes.
class LibraryCollectionsCubit extends Cubit<LibraryCollectionsState> {
  LibraryCollectionsCubit({required this._getAlbums, required this._getArtists})
    : super(const LibraryCollectionsState());

  final GetAlbumsUseCase _getAlbums;
  final GetArtistsUseCase _getArtists;

  Future<void> load() async {
    final albums = await _getAlbums(const NoParams());
    final artists = await _getArtists(const NoParams());
    if (isClosed) return;

    final failure =
        albums.fold((f) => f, (_) => null) ??
        artists.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(
        LibraryCollectionsState(
          status: LoadStatus.failure,
          albums: state.albums,
          artists: state.artists,
          errorMessage: failure.message,
        ),
      );
      return;
    }
    emit(
      LibraryCollectionsState(
        status: LoadStatus.ready,
        albums: albums.getOrElse(() => const []),
        artists: artists.getOrElse(() => const []),
      ),
    );
  }
}
