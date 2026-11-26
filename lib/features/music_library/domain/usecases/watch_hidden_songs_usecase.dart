import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';

class WatchHiddenSongsUseCase {
  const WatchHiddenSongsUseCase(this.repository);

  final MusicLibraryRepository repository;

  Stream<List<Song>> call() => repository.watchHiddenSongs();
}
