import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';

class WatchPlaylistsUseCase {
  const WatchPlaylistsUseCase(this.repository);

  final MusicLibraryRepository repository;

  Stream<List<Playlist>> call() => repository.watchPlaylists();
}
