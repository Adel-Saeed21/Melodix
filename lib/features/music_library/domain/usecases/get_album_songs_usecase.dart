import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';

class GetAlbumSongsUseCase implements UseCase<List<Song>, Album> {
  const GetAlbumSongsUseCase(this.repository);

  final MusicLibraryRepository repository;

  @override
  Future<Either<Failure, List<Song>>> call(Album album) =>
      repository.getAlbumSongs(album);
}
