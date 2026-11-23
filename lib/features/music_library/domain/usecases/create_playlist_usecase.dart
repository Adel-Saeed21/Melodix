import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';

class CreatePlaylistParams {
  const CreatePlaylistParams(this.name, {this.songIds = const []});

  final String name;
  final List<int> songIds;
}

/// Returns the new playlist's id.
class CreatePlaylistUseCase implements UseCase<int, CreatePlaylistParams> {
  const CreatePlaylistUseCase(this.repository);

  final MusicLibraryRepository repository;

  @override
  Future<Either<Failure, int>> call(CreatePlaylistParams params) =>
      repository.createPlaylist(params.name, songIds: params.songIds);
}
