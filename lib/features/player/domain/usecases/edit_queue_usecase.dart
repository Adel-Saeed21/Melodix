import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/player/domain/repositories/player_repository.dart';

/// Adds songs to what's playing: next, or at the end.
class EditQueueUseCase {
  const EditQueueUseCase(this.repository);

  final PlayerRepository repository;

  Future<void> playNext(List<Song> songs) => repository.playNext(songs);
  Future<void> addToQueue(List<Song> songs) => repository.addToQueue(songs);
}
