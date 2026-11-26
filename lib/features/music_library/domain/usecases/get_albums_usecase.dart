import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';

class GetAlbumsUseCase implements UseCase<List<Album>, NoParams> {
  const GetAlbumsUseCase(this.repository);

  final MusicLibraryRepository repository;

  @override
  Future<Either<Failure, List<Album>>> call(NoParams params) =>
      repository.getAlbums();
}
