import 'package:melodix/features/music_library/domain/repositories/library_sync_repository.dart';

class GetLastLibrarySyncUseCase {
  const GetLastLibrarySyncUseCase(this.repository);

  final LibrarySyncRepository repository;

  Future<DateTime?> call() => repository.lastSyncedAt();
}
