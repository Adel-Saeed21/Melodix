import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/repositories/playlist_repository.dart';

class ReorderPlaylistSongsParams {
  const ReorderPlaylistSongsParams(this.playlistId, this.orderedSongIds);

  final int playlistId;

  /// The songs as shown, in their new order.
  final List<int> orderedSongIds;
}

class ReorderPlaylistSongsUseCase
    implements UseCase<Unit, ReorderPlaylistSongsParams> {
  const ReorderPlaylistSongsUseCase(this.repository);

  final PlaylistRepository repository;

  @override
  Future<Either<Failure, Unit>> call(ReorderPlaylistSongsParams params) =>
      repository.reorderPlaylistSongs(params.playlistId, params.orderedSongIds);
}
