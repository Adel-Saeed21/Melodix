import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/video/domain/entities/video_library_changes.dart';
import 'package:melodix/features/video/domain/repositories/video_sync_repository.dart';

class VideoSyncParams extends Equatable {
  const VideoSyncParams({this.force = false});

  /// Scan everything even if the device says nothing changed (the user
  /// tapped Scan).
  final bool force;

  @override
  List<Object?> get props => [force];
}

/// Brings the saved video library in line with the device (safely and
/// cheaply: see [VideoSyncRepository.syncLibrary]).
class SyncVideoLibraryUseCase
    implements UseCase<VideoLibraryChanges, VideoSyncParams> {
  const SyncVideoLibraryUseCase(this.repository);

  final VideoSyncRepository repository;

  @override
  Future<Either<Failure, VideoLibraryChanges>> call(VideoSyncParams params) =>
      repository.syncLibrary(force: params.force);
}
