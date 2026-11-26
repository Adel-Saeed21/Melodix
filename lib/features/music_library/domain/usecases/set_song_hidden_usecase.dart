import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';

class SetSongHiddenParams {
  const SetSongHiddenParams(this.songId, {required this.hidden});

  final int songId;
  final bool hidden;
}

/// Hides a song from the library or brings it back.
class SetSongHiddenUseCase implements UseCase<Unit, SetSongHiddenParams> {
  const SetSongHiddenUseCase(this.repository);

  final MusicLibraryRepository repository;

  @override
  Future<Either<Failure, Unit>> call(SetSongHiddenParams params) =>
      repository.setSongHidden(params.songId, hidden: params.hidden);
}
