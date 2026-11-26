import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/repositories/playlist_repository.dart';

/// Params: the playlist id. Returns the new favorite value.
class TogglePlaylistFavoriteUseCase implements UseCase<bool, int> {
  const TogglePlaylistFavoriteUseCase(this.repository);

  final PlaylistRepository repository;

  @override
  Future<Either<Failure, bool>> call(int playlistId) =>
      repository.togglePlaylistFavorite(playlistId);
}
