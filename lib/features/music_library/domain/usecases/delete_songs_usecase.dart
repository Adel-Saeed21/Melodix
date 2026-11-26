import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';

/// Params: the song ids. Deletes the files from the device (with the
/// system's confirmation) and returns how many were deleted.
class DeleteSongsUseCase implements UseCase<int, List<int>> {
  const DeleteSongsUseCase(this.repository);

  final MusicLibraryRepository repository;

  /// False where deleting isn't possible (iOS); hide the action there.
  bool get isSupported => repository.canDeleteSongs;

  @override
  Future<Either<Failure, int>> call(List<int> songIds) =>
      repository.deleteSongs(songIds);
}
