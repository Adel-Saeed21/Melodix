import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';

class GetLastLibrarySyncUseCase {
  const GetLastLibrarySyncUseCase(this.repository);

  final MusicLibraryRepository repository;

  Future<DateTime?> call() => repository.lastSyncedAt();
}
