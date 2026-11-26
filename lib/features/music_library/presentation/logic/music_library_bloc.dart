import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/service/app_lifecycle_service.dart';
import 'package:melodix/core/entities/library_permission.dart';
import 'package:melodix/features/music_library/domain/entities/library_sync_result.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/usecases/check_library_permission_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_last_library_sync_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/open_library_settings_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/request_library_permission_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/sync_music_library_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_library_songs_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_library_sync_stage_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_event.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_state.dart';

/// Keeps the local music library in sync with the device.
///
/// * First launch: waits for access, then runs the initial scan.
/// * App startup: shows saved songs immediately and refreshes in the
///   background (no permission dialog).
/// * Manual refresh: rescans on request.
/// * Permission changes: re-checks access whenever the app resumes, syncing
///   when access was granted and reporting when it was revoked.
class MusicLibraryBloc extends Bloc<MusicLibraryEvent, MusicLibraryState> {
  MusicLibraryBloc({
    required this._checkPermission,
    required this._requestPermission,
    required this._syncLibrary,
    required this._getLastSync,
    required this._watchSongs,
    required this._watchSyncStage,
    required this._lifecycle,
    required this._openSettings,
    this.resumeSyncInterval = const Duration(minutes: 10),
  }) : super(const MusicLibraryState()) {
    on<MusicLibraryStarted>(_onStarted);
    on<MusicLibraryPermissionRequested>(_onPermissionRequested);
    on<MusicLibraryRefreshRequested>(_onRefreshRequested);
    on<MusicLibraryOpenSettingsRequested>((event, emit) => _openSettings());
    on<MusicLibraryAppResumed>(_onAppResumed);
    on<MusicLibrarySongsChanged>(_onSongsChanged);
    on<MusicLibrarySyncStageReached>(_onSyncStageReached);
  }

  final CheckLibraryPermissionUseCase _checkPermission;
  final RequestLibraryPermissionUseCase _requestPermission;
  final SyncMusicLibraryUseCase _syncLibrary;
  final GetLastLibrarySyncUseCase _getLastSync;
  final WatchLibrarySongsUseCase _watchSongs;
  final WatchLibrarySyncStageUseCase _watchSyncStage;
  final AppLifecycleService _lifecycle;
  final OpenLibrarySettingsUseCase _openSettings;

  /// On resume, rescan only if the last sync is older than this, so quickly
  /// switching apps doesn't trigger a scan every time.
  final Duration resumeSyncInterval;

  StreamSubscription<void>? _songsSubscription;
  StreamSubscription<void>? _resumeSubscription;
  StreamSubscription<void>? _stageSubscription;

  /// Syncs in progress. A forced refresh may run after a background sync,
  /// so [MusicLibraryState.isSyncing] stays true until both finish.
  int _syncsRunning = 0;

  /// A forced rescan is running or waiting; another one adds nothing.
  bool _forcedSyncPending = false;

  Future<void> _onStarted(
    MusicLibraryStarted event,
    Emitter<MusicLibraryState> emit,
  ) async {
    _songsSubscription ??= _watchSongs().listen(
      (update) => add(MusicLibrarySongsChanged(update)),
      // A failed reload keeps the songs shown; report it, don't crash.
      onError: addError,
    );
    _stageSubscription ??= _watchSyncStage().listen(
      (stage) => add(MusicLibrarySyncStageReached(stage)),
    );
    _resumeSubscription ??= _lifecycle.onResumed.listen(
      (_) => add(const MusicLibraryAppResumed()),
    );

    final lastSyncedAt = await _getLastSync();
    final permission = await _checkPermission();
    emit(state.copyWith(permission: permission, lastSyncedAt: lastSyncedAt));

    if (!permission.isGranted) {
      emit(state.copyWith(status: MusicLibraryStatus.permissionRequired));
      return;
    }
    await _sync(emit);
  }

  Future<void> _onPermissionRequested(
    MusicLibraryPermissionRequested event,
    Emitter<MusicLibraryState> emit,
  ) async {
    final permission = await _requestPermission();
    emit(state.copyWith(permission: permission));
    if (!permission.isGranted) {
      emit(state.copyWith(status: MusicLibraryStatus.permissionRequired));
      return;
    }
    await _sync(emit);
  }

  Future<void> _onRefreshRequested(
    MusicLibraryRefreshRequested event,
    Emitter<MusicLibraryState> emit,
  ) async {
    final permission = await _checkPermission();
    emit(state.copyWith(permission: permission));
    if (!permission.isGranted) {
      emit(state.copyWith(status: MusicLibraryStatus.permissionRequired));
      return;
    }
    // Smart unless a full re-read was asked for explicitly.
    await _sync(emit, force: event.full);
  }

  Future<void> _onAppResumed(
    MusicLibraryAppResumed event,
    Emitter<MusicLibraryState> emit,
  ) async {
    final wasGranted = state.hasPermission;
    final permission = await _checkPermission();
    emit(state.copyWith(permission: permission));

    if (!permission.isGranted) {
      // Access revoked (or still missing).
      emit(state.copyWith(status: MusicLibraryStatus.permissionRequired));
      return;
    }

    final lastSync = state.lastSyncedAt;
    final isStale =
        lastSync == null ||
        DateTime.now().difference(lastSync) >= resumeSyncInterval;
    // Access just granted in settings, or new music may have arrived.
    if (!wasGranted || isStale) await _sync(emit);
  }

  /// Progress of the running sync (ignored once it's over: a stage can't
  /// outlive its sync).
  void _onSyncStageReached(
    MusicLibrarySyncStageReached event,
    Emitter<MusicLibraryState> emit,
  ) {
    if (state.isSyncing) emit(state.copyWith(syncStage: event.stage));
  }

  /// Applies a library update. Single-song edits (play count, favourite,
  /// hiding) replace or drop just those songs: no full reload, and no
  /// emission at all if nothing visible changed.
  void _onSongsChanged(
    MusicLibrarySongsChanged event,
    Emitter<MusicLibraryState> emit,
  ) {
    final songs = event.update.applyTo(state.songs);
    if (songs == null) return;
    final becameReady =
        songs.isNotEmpty &&
        (state.status == MusicLibraryStatus.initial ||
            state.status == MusicLibraryStatus.failure);
    emit(
      state.copyWith(
        songs: songs,
        status: becameReady ? MusicLibraryStatus.ready : null,
      ),
    );
  }

  /// [force] scans even if the device reports no changes (manual refresh).
  ///
  /// A normal sync is skipped while another sync runs (that one covers it).
  /// A forced sync is not: the user asked for a full rescan, so it runs
  /// after the current one (the repository queues it).
  Future<void> _sync(
    Emitter<MusicLibraryState> emit, {
    bool force = false,
  }) async {
    if (force ? _forcedSyncPending : _syncsRunning > 0) return;

    if (_syncsRunning == 0) {
      final isFirstScan = state.lastSyncedAt == null && state.songs.isEmpty;
      emit(
        state.copyWith(
          status: isFirstScan
              ? MusicLibraryStatus.scanning
              : MusicLibraryStatus.ready,
          isSyncing: true,
          clearSyncStage: true,
          clearError: true,
        ),
      );
    }

    _syncsRunning++;
    if (force) _forcedSyncPending = true;
    final Either<Failure, LibrarySyncResult> result;
    try {
      result = await _syncLibrary(SyncLibraryParams(force: force));
    } finally {
      _syncsRunning--;
      if (force) _forcedSyncPending = false;
    }
    final isSyncing = _syncsRunning > 0;

    result.fold(
      (failure) {
        if (failure is PermissionFailure) {
          emit(
            state.copyWith(
              status: MusicLibraryStatus.permissionRequired,
              permission: failure.permanentlyDenied
                  ? LibraryPermission.permanentlyDenied
                  : LibraryPermission.denied,
              isSyncing: isSyncing,
              clearSyncStage: !isSyncing,
              errorMessage: failure.message,
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            status: state.songs.isEmpty
                ? MusicLibraryStatus.failure
                : MusicLibraryStatus.ready,
            isSyncing: isSyncing,
            clearSyncStage: !isSyncing,
            errorMessage: failure.message,
          ),
        );
      },
      (sync) => emit(
        state.copyWith(
          status: MusicLibraryStatus.ready,
          isSyncing: isSyncing,
          clearSyncStage: !isSyncing,
          lastSyncResult: sync,
          lastSyncedAt: sync.syncedAt,
        ),
      ),
    );
  }

  /// The visible songs now, then again each time they change. For screens
  /// that show part of the library live (an album's or artist's songs).
  Stream<List<Song>> librarySongs() => Stream.multi((controller) {
    var last = state.songs;
    controller.add(last);
    final sub = stream.listen(
      (s) {
        if (identical(s.songs, last)) return;
        last = s.songs;
        controller.add(last);
      },
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = sub.cancel;
  });

  @override
  Future<void> close() async {
    await _songsSubscription?.cancel();
    await _resumeSubscription?.cancel();
    await _stageSubscription?.cancel();
    return super.close();
  }
}
