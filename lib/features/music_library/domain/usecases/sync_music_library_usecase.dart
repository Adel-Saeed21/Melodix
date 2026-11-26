import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/entities/library_sync_result.dart';
import 'package:melodix/features/music_library/domain/repositories/library_sync_repository.dart';

class SyncLibraryParams {
  const SyncLibraryParams({this.force = false});

  /// Scan even if the device reports no changes (e.g. pull-to-refresh).
  final bool force;
}

class SyncMusicLibraryUseCase
    implements UseCase<LibrarySyncResult, SyncLibraryParams> {
  const SyncMusicLibraryUseCase(this.repository);

  final LibrarySyncRepository repository;

  @override
  Future<Either<Failure, LibrarySyncResult>> call(SyncLibraryParams params) =>
      repository.syncLibrary(force: params.force);
}
