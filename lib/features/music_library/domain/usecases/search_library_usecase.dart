import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/entities/library_search_results.dart';
import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';

/// Params: the search text. Matches songs (title, artist, album), artists,
/// albums (title or artist) and playlists (name), case-insensitively.
class SearchLibraryUseCase implements UseCase<LibrarySearchResults, String> {
  const SearchLibraryUseCase(this.repository);

  final MusicLibraryRepository repository;

  @override
  Future<Either<Failure, LibrarySearchResults>> call(String query) =>
      repository.searchLibrary(query);
}
