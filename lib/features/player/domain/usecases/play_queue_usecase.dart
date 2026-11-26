import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/player/domain/repositories/player_repository.dart';

class PlayQueueParams {
  const PlayQueueParams(
    this.songs, {
    this.startIndex = 0,
    this.title,
    this.shuffle,
  });

  final List<Song> songs;
  final int startIndex;
  final String? title;
  final bool? shuffle;
}

class PlayQueueUseCase {
  const PlayQueueUseCase(this.repository);

  final PlayerRepository repository;

  Future<void> call(PlayQueueParams params) {
    if (params.songs.isEmpty) return Future.value();
    final start = params.startIndex.clamp(0, params.songs.length - 1);
    return repository.playQueue(
      params.songs,
      startIndex: start,
      title: params.title,
      shuffle: params.shuffle,
    );
  }
}
