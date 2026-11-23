import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';

/// Params: the artist's name.
class GetArtistSongsUseCase implements UseCase<List<Song>, String> {
  const GetArtistSongsUseCase(this.repository);

  final MusicLibraryRepository repository;

  @override
  Future<Either<Failure, List<Song>>> call(String artistName) =>
      repository.getArtistSongs(artistName);
}
