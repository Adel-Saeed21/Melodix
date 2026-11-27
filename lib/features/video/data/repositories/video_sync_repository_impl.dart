import 'package:dartz/dartz.dart';
import 'package:melodix/features/video/data/datasources/video_local_storage.dart';
import 'package:melodix/core/errors/exceptions.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/video/data/datasources/video_service.dart';
import 'package:melodix/core/utils/single_flight.dart';
import 'package:melodix/features/video/data/repositories/video_errors.dart';
import 'package:melodix/features/video/domain/entities/video_library_changes.dart';
import 'package:melodix/features/video/domain/repositories/video_sync_repository.dart';

class VideoSyncRepositoryImpl implements VideoSyncRepository {
  VideoSyncRepositoryImpl({required this._service, required this._storage});

  final VideoService _service;
  final VideoLocalStorage _storage;

  /// Concurrent syncs share one run (a forced one isn't merged into a
  /// quick check: it gets its own, after it).
  final SingleFlight<Either<Failure, VideoLibraryChanges>> _check =
      SingleFlight();
  final SingleFlight<Either<Failure, VideoLibraryChanges>> _full =
      SingleFlight();

  @override
  Future<Either<Failure, VideoLibraryChanges>> syncLibrary({
    bool force = false,
  }) => force ? _full.run(() => _sync(force: true)) : _check.run(_sync);

  Future<Either<Failure, VideoLibraryChanges>> _sync({
    bool force = false,
  }) async {
    try {
      // Taken before reading: anything changing during the scan has a
      // newer fingerprint, so the next check catches it.
      final checkpoint = await _service.checkpoint();
      // Nothing changed: no scan, and nothing written (a routine check on
      // opening or returning to the app stays read-only).
      if (!force && checkpoint == await _storage.videoCheckpoint()) {
        return Right(
          VideoLibraryChanges(
            added: 0,
            updated: 0,
            removed: 0,
            total: await _storage.countVideos(),
          ),
        );
      }
      final scan = await _service.scan();
      final saved = await _storage.syncVideos(
        scan.videos,
        // Only the device's own count of 0 may empty a saved library (and
        // never when it only shows part of itself).
        confirmedEmpty: scan.deviceCount == 0 && !scan.partial,
        checkpoint: checkpoint,
        // Partial access: unseen videos still exist; keep them.
        keepMissing: scan.partial,
      );
      return Right(
        VideoLibraryChanges(
          added: saved.added,
          updated: saved.updated,
          removed: saved.removed,
          total: saved.total,
        ),
      );
    } on MediaPermissionException catch (e) {
      return Left(
        PermissionFailure(
          VideoErrors.permission,
          permanentlyDenied: e.permanentlyDenied,
        ),
      );
    } on MediaQueryException catch (e, stack) {
      logVideoProblem(
        'Video sync stopped, library left unchanged: ${e.message}',
        e,
        stack,
      );
      return const Left(LibraryFailure(VideoErrors.sync));
    } catch (e, stack) {
      logVideoProblem('Video sync failed, library left unchanged', e, stack);
      return const Left(LibraryFailure(VideoErrors.sync));
    }
  }
}
