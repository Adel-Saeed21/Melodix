import 'package:melodix/features/player/domain/entities/playback_progress.dart';
import 'package:melodix/features/player/domain/repositories/player_repository.dart';

/// Where playback is in the current song, as it moves.
class WatchPlaybackProgressUseCase {
  const WatchPlaybackProgressUseCase(this.repository);

  final PlayerRepository repository;

  PlaybackProgress get current => repository.progress;

  Stream<PlaybackProgress> call() => repository.watchProgress();
}
