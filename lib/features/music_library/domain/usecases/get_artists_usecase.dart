import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/entities/artist.dart';
import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';

class GetArtistsUseCase implements UseCase<List<Artist>, NoParams> {
  const GetArtistsUseCase(this.repository);

  final MusicLibraryRepository repository;

  @override
  Future<Either<Failure, List<Artist>>> call(NoParams params) =>
      repository.getArtists();
}
