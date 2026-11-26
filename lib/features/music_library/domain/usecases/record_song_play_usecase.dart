import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';

/// Params: the song id. Counts one play ("Most played") and updates the
/// recently played list. The audio player calls this when a song starts.
class RecordSongPlayUseCase implements UseCase<Unit, int> {
  const RecordSongPlayUseCase(this.repository);

  final MusicLibraryRepository repository;

  @override
  Future<Either<Failure, Unit>> call(int songId) =>
      repository.recordPlay(songId);
}
