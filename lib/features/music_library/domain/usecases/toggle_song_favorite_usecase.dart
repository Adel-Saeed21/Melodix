import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';

/// Params: the song id. Returns the new favorite value.
class ToggleSongFavoriteUseCase implements UseCase<bool, int> {
  const ToggleSongFavoriteUseCase(this.repository);

  final MusicLibraryRepository repository;

  @override
  Future<Either<Failure, bool>> call(int songId) =>
      repository.toggleFavorite(songId);
}
