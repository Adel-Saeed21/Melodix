import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/domain/repositories/playlist_repository.dart';

class GetPlaylistsUseCase implements UseCase<List<Playlist>, NoParams> {
  const GetPlaylistsUseCase(this.repository);

  final PlaylistRepository repository;

  @override
  Future<Either<Failure, List<Playlist>>> call(NoParams params) =>
      repository.getPlaylists();
}
