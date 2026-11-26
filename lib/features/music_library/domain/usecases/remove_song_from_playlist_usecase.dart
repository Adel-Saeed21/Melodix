import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/repositories/playlist_repository.dart';

class RemoveSongFromPlaylistParams {
  const RemoveSongFromPlaylistParams(this.playlistId, this.songId);

  final int playlistId;
  final int songId;
}

class RemoveSongFromPlaylistUseCase
    implements UseCase<Unit, RemoveSongFromPlaylistParams> {
  const RemoveSongFromPlaylistUseCase(this.repository);

  final PlaylistRepository repository;

  @override
  Future<Either<Failure, Unit>> call(RemoveSongFromPlaylistParams params) =>
      repository.removeSongFromPlaylist(params.playlistId, params.songId);
}
