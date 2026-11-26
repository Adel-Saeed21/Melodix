import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/entities/artist.dart';
import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';

/// Params: the artist's name.
class GetArtistUseCase implements UseCase<Artist?, String> {
  const GetArtistUseCase(this.repository);

  final MusicLibraryRepository repository;

  @override
  Future<Either<Failure, Artist?>> call(String name) =>
      repository.getArtist(name);
}
