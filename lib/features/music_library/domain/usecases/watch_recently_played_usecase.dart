import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/repositories/recently_played_repository.dart';

/// The recently played songs, newest first, kept up to date.
class WatchRecentlyPlayedUseCase {
  const WatchRecentlyPlayedUseCase(this.repository);

  final RecentlyPlayedRepository repository;

  Stream<List<Song>> call() => repository.watchRecentlyPlayed();
}
