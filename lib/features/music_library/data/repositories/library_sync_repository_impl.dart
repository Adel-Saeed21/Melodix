import 'dart:developer' as developer;

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:melodix/features/music_library/data/datasources/music_local_storage.dart';
import 'package:melodix/core/errors/exceptions.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/music_library/data/datasources/audio_library_delta_source.dart';
import 'package:melodix/features/music_library/data/datasources/music_file_filter.dart';
import 'package:melodix/core/service/permission_handling_service.dart';
import 'package:melodix/core/utils/single_flight.dart';
import 'package:melodix/features/music_library/data/repositories/repository_guard.dart';
import 'package:melodix/features/music_library/data/sync/full_library_scan.dart';
import 'package:melodix/features/music_library/data/sync/incremental_library_scan.dart';
import 'package:melodix/features/music_library/data/sync/library_sync_plan.dart';
import 'package:melodix/features/music_library/domain/entities/library_sync_result.dart';
import 'package:melodix/features/music_library/domain/entities/library_sync_stage.dart';
import 'package:melodix/features/music_library/domain/repositories/library_sync_repository.dart';

/// Orchestrates a library sync:
///
/// 1. checks permission (no dialog),
/// 2. reads MediaStore's checkpoint,
/// 3. plans the sync ([planLibrarySync]): skip, incremental or full,
/// 4. runs the matching strategy ([IncrementalLibraryScan] /
///    [FullLibraryScan]),
/// 5. maps errors to [Failure]s.
///
/// Data safety: nothing is deleted and the checkpoint is not moved unless
/// every MediaStore query succeeded. A missing permission, a failed or
/// partial query and an unconfirmed empty result all end the sync with a
/// [Failure] before storage is touched.
class LibrarySyncRepositoryImpl implements LibrarySyncRepository {
  LibrarySyncRepositoryImpl({
    required this._permissionService,
    required this._deltaSource,
    required this._storage,
    required this._fullScan,
    required this._incrementalScan,
  });

  final PermissionHandlingService _permissionService;
  final AudioLibraryDeltaSource _deltaSource;
  final MusicLocalStorage _storage;
  final FullLibraryScan _fullScan;
  final IncrementalLibraryScan _incrementalScan;

  final StreamController<LibrarySyncStage> _stages =
      StreamController.broadcast();

  /// Concurrent syncs share one run.
  final SingleFlight<Either<Failure, LibrarySyncResult>> _flight =
      SingleFlight();

  @override
  Future<Either<Failure, LibrarySyncResult>> syncLibrary({
    bool force = false,
  }) => force
      // A forced sync (pull-to-refresh) gets its own full scan.
      ? _flight.runAfterCurrent(() => _sync(force: true))
      : _flight.run(() => _sync(force: false));

  @override
  Stream<LibrarySyncStage> watchSyncStage() => _stages.stream;

  @override
  Future<DateTime?> lastSyncedAt() => _storage.getLastSyncedAt();

  void _reached(LibrarySyncStage stage) {
    if (!_stages.isClosed) _stages.add(stage);
  }

  Future<Either<Failure, LibrarySyncResult>> _sync({
    required bool force,
  }) async {
    try {
      _reached(LibrarySyncStage.checking);
      await _requirePermission();
      // Read before anything else: changes made during the sync get a later
      // generation and are picked up next time.
      final current = await _deltaSource.currentCheckpoint();
      final plan = planLibrarySync(
        force: force,
        current: current,
        saved: decodeSyncCheckpoint(await _storage.getSyncCheckpoint()),
        rulesVersion: MusicFileFilter.rulesVersion,
      );
      return Right(await _execute(plan, current));
    } on MediaPermissionException catch (e) {
      _log('Library sync stopped: no permission to read music');
      return Left(
        PermissionFailure(
          LibraryErrors.permission,
          permanentlyDenied: e.permanentlyDenied,
        ),
      );
    } on MediaQueryException catch (e, stack) {
      _log('Sync stopped, library left unchanged: ${e.message}', e, stack);
      return const Left(LibraryFailure(LibraryErrors.sync));
    } catch (e, stack) {
      _log('Sync failed, library left unchanged', e, stack);
      return const Left(LibraryFailure(LibraryErrors.sync));
    }
  }

  /// Without permission Android answers queries with an EMPTY library (not
  /// an error), so this must run first. Status only: no dialog here.
  Future<void> _requirePermission() async {
    final permission = await _permissionService.audioStatus();
    if (!permission.isGranted) {
      throw MediaPermissionException(
        permanentlyDenied:
            permission == MediaPermissionStatus.permanentlyDenied,
      );
    }
  }

  Future<LibrarySyncResult> _execute(
    LibrarySyncPlan plan,
    MediaStoreCheckpoint? current,
  ) async {
    switch (plan) {
      case SkipSync():
        await _storage.markCheckedUnchanged();
        return LibrarySyncResult(
          added: 0,
          updated: 0,
          removed: 0,
          total: await _storage.countSongs(),
          syncedAt: await _syncedAt(),
          skipped: true,
        );
      case IncrementalSync(:final since, :final version):
        _reached(LibrarySyncStage.reading);
        final applied = await _incrementalScan.run(
          since,
          version,
          onSaving: _onSaving,
        );
        // Null: MediaStore was rebuilt while reading, so generations from
        // the old database mean nothing. Read everything instead.
        if (applied != null) return _toResult(applied, incremental: true);
        return _toResult(await _fullScan.run(current, onSaving: _onSaving));
      case FullSync(:final reason):
        _log('Full library scan: ${reason.name}');
        _reached(LibrarySyncStage.reading);
        return _toResult(await _fullScan.run(current, onSaving: _onSaving));
    }
  }

  void _onSaving() => _reached(LibrarySyncStage.saving);

  Future<LibrarySyncResult> _toResult(
    SongSyncResult saved, {
    bool incremental = false,
  }) async => LibrarySyncResult(
    added: saved.added,
    updated: saved.updated,
    removed: saved.removed,
    total: saved.total,
    syncedAt: await _syncedAt(),
    incremental: incremental,
  );

  Future<DateTime> _syncedAt() async =>
      await _storage.getLastSyncedAt() ?? DateTime.now();

  static void _log(String message, [Object? error, StackTrace? stack]) =>
      developer.log(
        message,
        name: 'melodix.library_sync',
        error: error,
        stackTrace: stack,
      );
}
