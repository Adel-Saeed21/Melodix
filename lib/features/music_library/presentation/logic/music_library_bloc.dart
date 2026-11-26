import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/service/app_lifecycle_service.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/entities/library_permission.dart';
import 'package:melodix/features/music_library/domain/usecases/check_library_permission_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_last_library_sync_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/open_library_settings_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/request_library_permission_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/sync_music_library_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_library_songs_usecase.dart';
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
  }

  final CheckLibraryPermissionUseCase _checkPermission;
  final RequestLibraryPermissionUseCase _requestPermission;
  final SyncMusicLibraryUseCase _syncLibrary;
  final GetLastLibrarySyncUseCase _getLastSync;
  final WatchLibrarySongsUseCase _watchSongs;
  final AppLifecycleService _lifecycle;
  final OpenLibrarySettingsUseCase _openSettings;

  /// On resume, rescan only if the last sync is older than this, so quickly
  /// switching apps doesn't trigger a scan every time.
  final Duration resumeSyncInterval;

  StreamSubscription<void>? _songsSubscription;
  StreamSubscription<void>? _resumeSubscription;

  Future<void> _onStarted(
    MusicLibraryStarted event,
    Emitter<MusicLibraryState> emit,
  ) async {
    _songsSubscription ??= _watchSongs().listen(
      (songs) => add(MusicLibrarySongsChanged(songs)),
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
    await _sync(emit);
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

  void _onSongsChanged(
    MusicLibrarySongsChanged event,
    Emitter<MusicLibraryState> emit,
  ) {
    final becameReady =
        event.songs.isNotEmpty &&
        (state.status == MusicLibraryStatus.initial ||
            state.status == MusicLibraryStatus.failure);
    emit(
      state.copyWith(
        songs: event.songs,
        status: becameReady ? MusicLibraryStatus.ready : null,
      ),
    );
  }

  Future<void> _sync(Emitter<MusicLibraryState> emit) async {
    if (state.isSyncing) return;

    final isFirstScan = state.lastSyncedAt == null && state.songs.isEmpty;
    emit(
      state.copyWith(
        status: isFirstScan
            ? MusicLibraryStatus.scanning
            : MusicLibraryStatus.ready,
        isSyncing: true,
        clearError: true,
      ),
    );

    final result = await _syncLibrary(const NoParams());

    result.fold(
      (failure) {
        if (failure is PermissionFailure) {
          emit(
            state.copyWith(
              status: MusicLibraryStatus.permissionRequired,
              permission: failure.permanentlyDenied
                  ? LibraryPermission.permanentlyDenied
                  : LibraryPermission.denied,
              isSyncing: false,
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
            isSyncing: false,
            errorMessage: failure.message,
          ),
        );
      },
      (sync) => emit(
        state.copyWith(
          status: MusicLibraryStatus.ready,
          isSyncing: false,
          lastSyncResult: sync,
          lastSyncedAt: sync.syncedAt,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _songsSubscription?.cancel();
    await _resumeSubscription?.cancel();
    return super.close();
  }
}
