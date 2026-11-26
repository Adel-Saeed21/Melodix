import 'package:melodix/features/music_library/domain/entities/library_sync_stage.dart';
import 'package:melodix/features/music_library/domain/repositories/library_sync_repository.dart';

/// The stage each library sync reaches, as it reaches it.
class WatchLibrarySyncStageUseCase {
  const WatchLibrarySyncStageUseCase(this.repository);

  final LibrarySyncRepository repository;

  Stream<LibrarySyncStage> call() => repository.watchSyncStage();
}
