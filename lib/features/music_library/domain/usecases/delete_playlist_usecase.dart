import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';

/// Params: the playlist id. Songs stay in the library.
class DeletePlaylistUseCase implements UseCase<Unit, int> {
  const DeletePlaylistUseCase(this.repository);

  final MusicLibraryRepository repository;

  @override
  Future<Either<Failure, Unit>> call(int playlistId) =>
      repository.deletePlaylist(playlistId);
}
