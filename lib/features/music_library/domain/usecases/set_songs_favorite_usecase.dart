import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';

class SetSongsFavoriteParams {
  const SetSongsFavoriteParams(this.songIds, {required this.favorite});

  final List<int> songIds;
  final bool favorite;
}

class SetSongsFavoriteUseCase implements UseCase<Unit, SetSongsFavoriteParams> {
  const SetSongsFavoriteUseCase(this.repository);

  final MusicLibraryRepository repository;

  @override
  Future<Either<Failure, Unit>> call(SetSongsFavoriteParams params) =>
      repository.setSongsFavorite(params.songIds, favorite: params.favorite);
}
