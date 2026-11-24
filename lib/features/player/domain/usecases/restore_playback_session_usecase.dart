import 'package:melodix/features/player/domain/repositories/player_repository.dart';

/// Loads the last listening session (paused) on app start.
class RestorePlaybackSessionUseCase {
  const RestorePlaybackSessionUseCase(this.repository);

  final PlayerRepository repository;

  Future<void> call() => repository.restoreLastSession();
}
