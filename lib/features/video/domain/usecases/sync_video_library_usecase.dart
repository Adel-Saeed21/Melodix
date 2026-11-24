import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/video/domain/entities/video_library_changes.dart';
import 'package:melodix/features/video/domain/repositories/video_library_repository.dart';

/// Brings the saved video library in line with the device (safely: see
/// [VideoLibraryRepository.syncLibrary]).
class SyncVideoLibraryUseCase
    implements UseCase<VideoLibraryChanges, NoParams> {
  const SyncVideoLibraryUseCase(this.repository);

  final VideoLibraryRepository repository;

  @override
  Future<Either<Failure, VideoLibraryChanges>> call(NoParams params) =>
      repository.syncLibrary();
}
