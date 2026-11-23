import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';

/// Params: the playlist id.
class GetPlaylistSongsUseCase implements UseCase<List<Song>, int> {
  const GetPlaylistSongsUseCase(this.repository);

  final MusicLibraryRepository repository;

  @override
  Future<Either<Failure, List<Song>>> call(int playlistId) =>
      repository.getPlaylistSongs(playlistId);
}
