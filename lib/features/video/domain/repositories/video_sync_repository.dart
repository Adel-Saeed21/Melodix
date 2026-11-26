import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/video/domain/entities/video_library_changes.dart';

/// Keeps the saved library in line with the videos on the device.
abstract interface class VideoSyncRepository {
  /// Brings the saved library in line with the device. Never asks for
  /// permission (fails with [PermissionFailure] instead) and never changes
  /// the saved library when the device can't be read completely
  /// ([LibraryFailure]). Concurrent calls share one scan.
  ///
  /// First asks the device for a fingerprint of its videos (cheap): if it's
  /// the same as at the last sync, nothing changed and the full scan is
  /// skipped. [force]: scan anyway (the user tapped Scan).
  Future<Either<Failure, VideoLibraryChanges>> syncLibrary({
    bool force = false,
  });
}
