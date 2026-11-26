import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';

class RenamePlaylistParams {
  const RenamePlaylistParams(this.playlistId, this.name);

  final int playlistId;
  final String name;
}

class RenamePlaylistUseCase implements UseCase<Unit, RenamePlaylistParams> {
  const RenamePlaylistUseCase(this.repository);

  final MusicLibraryRepository repository;

  @override
  Future<Either<Failure, Unit>> call(RenamePlaylistParams params) =>
      repository.renamePlaylist(params.playlistId, params.name);
}
