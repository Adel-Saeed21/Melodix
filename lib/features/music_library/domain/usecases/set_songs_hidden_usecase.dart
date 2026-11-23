import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';

class SetSongsHiddenParams {
  const SetSongsHiddenParams(this.songIds, {required this.hidden});

  final List<int> songIds;
  final bool hidden;
}

class SetSongsHiddenUseCase implements UseCase<Unit, SetSongsHiddenParams> {
  const SetSongsHiddenUseCase(this.repository);

  final MusicLibraryRepository repository;

  @override
  Future<Either<Failure, Unit>> call(SetSongsHiddenParams params) =>
      repository.setSongsHidden(params.songIds, hidden: params.hidden);
}
