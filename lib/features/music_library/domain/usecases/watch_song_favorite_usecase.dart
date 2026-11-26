import 'package:melodix/features/music_library/domain/repositories/song_repository.dart';

/// Whether a song is a favourite, now and whenever that changes (from
/// anywhere in the app or the media notification).
class WatchSongFavoriteUseCase {
  const WatchSongFavoriteUseCase(this.repository);

  final SongRepository repository;

  Stream<bool> call(int songId) => repository.watchFavorite(songId);
}
