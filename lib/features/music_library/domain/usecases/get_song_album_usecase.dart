import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';

class GetSongAlbumUseCase implements UseCase<Album?, Song> {
  const GetSongAlbumUseCase(this.repository);

  final MusicLibraryRepository repository;

  @override
  Future<Either<Failure, Album?>> call(Song song) =>
      repository.getAlbumForSong(song);
}
