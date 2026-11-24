import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/domain/repositories/player_repository.dart';

class PlaybackControlsUseCase {
  const PlaybackControlsUseCase(this.repository);

  final PlayerRepository repository;

  Future<void> play() => repository.play();
  Future<void> pause() => repository.pause();
  Future<void> seek(Duration position) => repository.seek(position);
  Future<void> next() => repository.next();
  Future<void> skipToIndex(int index) => repository.skipToIndex(index);
  Future<void> previous() => repository.previous();
  Future<void> setRepeatMode(PlaybackRepeat mode) =>
      repository.setRepeatMode(mode);
  Future<void> setShuffle(bool enabled) => repository.setShuffle(enabled);
}
