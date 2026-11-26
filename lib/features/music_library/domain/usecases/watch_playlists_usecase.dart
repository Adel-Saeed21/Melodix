import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/domain/repositories/playlist_repository.dart';

class WatchPlaylistsUseCase {
  const WatchPlaylistsUseCase(this.repository);

  final PlaylistRepository repository;

  Stream<List<Playlist>> call() => repository.watchPlaylists();
}
