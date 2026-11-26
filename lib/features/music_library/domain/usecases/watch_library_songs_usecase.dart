import 'package:melodix/features/music_library/domain/entities/library_update.dart';
import 'package:melodix/features/music_library/domain/repositories/song_repository.dart';

/// The visible library as a series of [LibraryUpdate]s (whole list first,
/// then only what changed).
class WatchLibrarySongsUseCase {
  const WatchLibrarySongsUseCase(this.repository);

  final SongRepository repository;

  Stream<LibraryUpdate> call() => repository.watchLibrary();
}
