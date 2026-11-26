import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/repositories/recently_played_repository.dart';

/// Forgets the listening history (play counts stay).
class ClearRecentlyPlayedUseCase implements UseCase<Unit, NoParams> {
  const ClearRecentlyPlayedUseCase(this.repository);

  final RecentlyPlayedRepository repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      repository.clearRecentlyPlayed();
}
