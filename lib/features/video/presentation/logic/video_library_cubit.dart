import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/entities/library_permission.dart';
import 'package:melodix/features/music_library/domain/usecases/open_library_settings_usecase.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/domain/entities/video_library_changes.dart';
import 'package:melodix/features/video/domain/usecases/sync_video_library_usecase.dart';
import 'package:melodix/features/video/domain/usecases/toggle_video_favorite_usecase.dart';
import 'package:melodix/features/video/domain/usecases/video_permission_usecases.dart';
import 'package:melodix/features/video/domain/usecases/watch_videos_usecase.dart';

enum VideoLibraryStatus { loading, permissionRequired, ready }

class VideoLibraryState extends Equatable {
  const VideoLibraryState({
    this.status = VideoLibraryStatus.loading,
    this.permission,
    this.videos = const [],
    this.isScanning = false,
  });

  final VideoLibraryStatus status;
  final LibraryPermission? permission;

  /// Every saved video, newest first.
  final List<Video> videos;
  final bool isScanning;

  /// Started but unfinished videos, most recently watched first.
  List<Video> get continueWatching {
    final started = [
      for (final v in videos)
        if (v.canResume) v,
    ];
    final never = DateTime.fromMillisecondsSinceEpoch(0);
    started.sort(
      (a, b) => (b.lastPlayedAt ?? never).compareTo(a.lastPlayedAt ?? never),
    );
    return started.length > 10 ? started.sublist(0, 10) : started;
  }

  VideoLibraryState copyWith({
    VideoLibraryStatus? status,
    LibraryPermission? permission,
    List<Video>? videos,
    bool? isScanning,
  }) => VideoLibraryState(
    status: status ?? this.status,
    permission: permission ?? this.permission,
    videos: videos ?? this.videos,
    isScanning: isScanning ?? this.isScanning,
  );

  @override
  List<Object?> get props => [status, permission, videos, isScanning];
}

/// The Videos tab: the saved library (shown at once, live) kept in line
/// with the device.
///
/// Same rules as the music library:
/// * the saved videos show immediately; the device is scanned behind them;
/// * a scan never shows a permission dialog: only [requestPermission]
///   does, from the user's tap;
/// * returning to the app re-checks access (it may have been granted in
///   the settings) and re-scans at most every [resumeScanInterval];
/// * scans never overlap (the repository shares a running one).
class VideoLibraryCubit extends Cubit<VideoLibraryState> {
  VideoLibraryCubit({
    required this._watchVideos,
    required this._sync,
    required this._checkPermission,
    required this._requestPermission,
    required this._openSettings,
    required this._toggleFavorite,
    required this._appResumed,
    DateTime Function()? clock,
    this.resumeScanInterval = const Duration(minutes: 2),
  }) : _clock = clock ?? DateTime.now,
       super(const VideoLibraryState());

  final WatchVideosUseCase _watchVideos;
  final SyncVideoLibraryUseCase _sync;
  final CheckVideoPermissionUseCase _checkPermission;
  final RequestVideoPermissionUseCase _requestPermission;
  final OpenLibrarySettingsUseCase _openSettings;
  final ToggleVideoFavoriteUseCase _toggleFavorite;
  final Stream<void> _appResumed;
  final DateTime Function() _clock;
  final Duration resumeScanInterval;

  StreamSubscription<List<Video>>? _videos;
  StreamSubscription<void>? _resumed;
  DateTime? _lastScan;

  /// Shows the saved videos and checks the device. Safe to call twice.
  Future<void> start() async {
    if (_videos != null) return;
    _videos = _watchVideos().listen((videos) {
      if (!isClosed) emit(state.copyWith(videos: videos));
    });
    _resumed = _appResumed.listen((_) => _onResumed());
    await _checkAndScan();
  }

  /// Looks for added, changed and removed videos. Returns what changed (or
  /// why it failed); null if a scan was already running.
  Future<Either<Failure, VideoLibraryChanges>?> scan() async {
    if (state.isScanning || isClosed) return null;
    emit(state.copyWith(isScanning: true));
    final result = await _sync(const NoParams());
    _lastScan = _clock();
    if (isClosed) return result;
    final failure = result.fold((f) => f, (_) => null);
    if (failure is PermissionFailure) {
      emit(
        state.copyWith(
          isScanning: false,
          status: VideoLibraryStatus.permissionRequired,
          permission: failure.permanentlyDenied
              ? LibraryPermission.permanentlyDenied
              : LibraryPermission.denied,
        ),
      );
    } else {
      emit(state.copyWith(isScanning: false));
    }
    return result;
  }

  /// Shows the system dialog (from the user's tap), then scans if allowed.
  Future<void> requestPermission() async {
    final permission = await _requestPermission();
    if (isClosed) return;
    await _apply(permission);
  }

  /// ♥ / un-♥ a video (the list updates by itself: it's live). Returns
  /// the new value; null if it couldn't be saved.
  Future<bool?> toggleFavorite(String videoId) async {
    final result = await _toggleFavorite(videoId);
    return result.fold((_) => null, (isFavorite) => isFavorite);
  }

  /// For a permanently denied permission: the app's settings page. Coming
  /// back re-checks it (see [start]).
  Future<void> openSettings() => _openSettings();

  Future<void> _checkAndScan() async {
    final permission = await _checkPermission();
    if (isClosed) return;
    await _apply(permission);
  }

  Future<void> _apply(LibraryPermission permission) async {
    if (permission != LibraryPermission.granted) {
      emit(
        state.copyWith(
          status: VideoLibraryStatus.permissionRequired,
          permission: permission,
        ),
      );
      return;
    }
    emit(
      state.copyWith(status: VideoLibraryStatus.ready, permission: permission),
    );
    await scan();
  }

  void _onResumed() {
    if (state.status == VideoLibraryStatus.permissionRequired) {
      unawaited(_checkAndScan());
      return;
    }
    final last = _lastScan;
    if (last == null || _clock().difference(last) >= resumeScanInterval) {
      unawaited(scan());
    }
  }

  @override
  Future<void> close() async {
    await _videos?.cancel();
    await _resumed?.cancel();
    return super.close();
  }
}
