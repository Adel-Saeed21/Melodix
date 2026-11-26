import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';

class WatchLibrarySongsUseCase {
  const WatchLibrarySongsUseCase(this.repository);

  final MusicLibraryRepository repository;

  Stream<List<Song>> call() => repository.watchSongs();
}
