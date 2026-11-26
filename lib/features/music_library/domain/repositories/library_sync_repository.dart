import 'package:dartz/dartz.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/music_library/domain/entities/library_sync_result.dart';
import 'package:melodix/features/music_library/domain/entities/library_sync_stage.dart';

/// Keeps the saved library in line with the music on the device.
abstract interface class LibrarySyncRepository {
  /// Brings the saved library in line with the device. Unless [force] is
  /// true, it first asks the device whether its audio library changed since
  /// the last scan and skips the scan when it didn't. Concurrent calls share
  /// one scan.
  ///
  /// Fails with [PermissionFailure] without access, [LibraryFailure] on
  /// other errors. A failed sync never changes the saved library.
  Future<Either<Failure, LibrarySyncResult>> syncLibrary({bool force = false});

  /// The stage of each sync as it gets there (checking, reading, saving),
  /// for showing progress. A sync that finds nothing to do ends after
  /// checking.
  Stream<LibrarySyncStage> watchSyncStage();

  /// When the library was last synced; null before the first scan.
  Future<DateTime?> lastSyncedAt();
}
