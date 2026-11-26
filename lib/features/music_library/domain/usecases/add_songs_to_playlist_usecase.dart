import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/repositories/playlist_repository.dart';

class AddSongsToPlaylistParams {
  const AddSongsToPlaylistParams(this.playlistId, this.songIds);

  final int playlistId;
  final List<int> songIds;
}

/// Returns how many songs were added (songs already present are skipped).
class AddSongsToPlaylistUseCase
    implements UseCase<int, AddSongsToPlaylistParams> {
  const AddSongsToPlaylistUseCase(this.repository);

  final PlaylistRepository repository;

  @override
  Future<Either<Failure, int>> call(AddSongsToPlaylistParams params) =>
      repository.addSongsToPlaylist(params.playlistId, params.songIds);
}
