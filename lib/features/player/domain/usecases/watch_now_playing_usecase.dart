import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/domain/repositories/player_repository.dart';

class WatchNowPlayingUseCase {
  const WatchNowPlayingUseCase(this.repository);

  final PlayerRepository repository;

  NowPlaying get current => repository.current;

  Stream<NowPlaying> call() => repository.watch();
}
