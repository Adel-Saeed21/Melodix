import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/entities/library_sync_result.dart';
import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';

class SyncMusicLibraryUseCase implements UseCase<LibrarySyncResult, NoParams> {
  const SyncMusicLibraryUseCase(this.repository);

  final MusicLibraryRepository repository;

  @override
  Future<Either<Failure, LibrarySyncResult>> call(NoParams params) =>
      repository.syncLibrary();
}
