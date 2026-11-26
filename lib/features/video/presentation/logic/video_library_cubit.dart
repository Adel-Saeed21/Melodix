import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/entities/library_permission.dart';
import 'package:melodix/core/usecase/open_app_settings_usecase.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/domain/entities/video_library_changes.dart';
import 'package:melodix/features/video/domain/entities/video_progress.dart';
import 'package:melodix/features/video/domain/usecases/video_progress_usecases.dart';
import 'package:melodix/features/video/domain/usecases/sync_video_library_usecase.dart';
import 'package:melodix/features/video/domain/usecases/video_permission_usecases.dart';
import 'package:melodix/features/video/domain/usecases/watch_videos_usecase.dart';

enum VideoLibraryStatus { loading, permissionRequired, ready }

class VideoLibraryState extends Equatable {
  const VideoLibraryState({
    this.status = VideoLibraryStatus.loading,
    this.permission,
    this.videos = const [],
    this.progress = const {},
    this.continueWatching = const [],
    this.isScanning = false,
  });

  final VideoLibraryStatus status;
  final LibraryPermission? permission;

  /// Every saved video, newest first.
  final List<Video> videos;
  final bool isScanning;

  /// How much of each played video was watched, by id.
  final Map<String, VideoProgress> progress;

  /// Started but unfinished videos, most recently watched first (at most
  /// [continueWatchingLimit]).
  final List<Video> continueWatching;

  static const int continueWatchingLimit = 10;

  VideoLibraryState copyWith({
    VideoLibraryStatus? status,
    LibraryPermission? permission,
    List<Video>? videos,
    Map<String, VideoProgress>? progress,
    bool? isScanning,
  }) {
    final newVideos = videos ?? this.videos;
    final newProgress = progress ?? this.progress;
    return VideoLibraryState(
      status: status ?? this.status,
      permission: permission ?? this.permission,
      videos: newVideos,
      progress: newProgress,
      // Worked out once per change of either, not on every build.
      continueWatching: videos == null && progress == null
          ? continueWatching
          : _continueWatching(newVideos, newProgress),
      isScanning: isScanning ?? this.isScanning,
    );
  }

  static List<Video> _continueWatching(
    List<Video> videos,
    Map<String, VideoProgress> progress,
  ) {
    if (progress.isEmpty) return const [];
    final started = [
      for (final v in videos)
        if (progress[v.id]?.canResume(v.duration) ?? false) v,
    ];
    final never = DateTime.fromMillisecondsSinceEpoch(0);
    DateTime played(Video v) => progress[v.id]?.lastPlayedAt ?? never;
    started.sort((a, b) => played(b).compareTo(played(a)));
    return started.length > continueWatchingLimit
        ? started.sublist(0, continueWatchingLimit)
        : started;
  }

  @override
  List<Object?> get props => [
    status,
    permission,
    videos,
    progress,
    continueWatching,
    isScanning,
  ];
}

/// The Videos tab: the saved library (shown at once, live) kept in line
/// with the device.
///
/// Same rules as the music library:
/// * the saved videos show immediately; the device is scanned behind them;
/// * a scan never shows a permission dialog: only [requestPermission]
///   does, from the user's tap;
/// * returning to the app re-checks access (it may have been granted in
///   the settings) and checks for changes at most every
///   [resumeScanInterval];
/// * automatic syncs first ask the device whether anything changed (two
///   tiny queries) and only read every video when it did; they show no
///   spinner (unless there's nothing to show yet). The Scan button always
///   reads everything, with a spinner;
/// * automatic syncs never run while a video is open (asked of
///   `isPlaybackActive` at that moment): they wait until it's closed
///   (`playbackActive` says when), so playback never stutters for one;
/// * scans never overlap (the repository shares a running one).
class VideoLibraryCubit extends Cubit<VideoLibraryState> {
  VideoLibraryCubit({
    required this._watchVideos,
    required this._sync,
    required this._checkPermission,
    required this._requestPermission,
    required this._openSettings,
    required this._watchProgress,
    required this._appResumed,
    DateTime Function()? clock,
    bool Function()? isPlaybackActive,
    this._playbackActive = const Stream.empty(),
    this.resumeScanInterval = const Duration(minutes: 5),
  }) : _clock = clock ?? DateTime.now,
       _isPlaybackActive = isPlaybackActive ?? _never,
       super(const VideoLibraryState());

  final WatchVideosUseCase _watchVideos;
  final SyncVideoLibraryUseCase _sync;
  final CheckVideoPermissionUseCase _checkPermission;
  final RequestVideoPermissionUseCase _requestPermission;
  final OpenAppSettingsUseCase _openSettings;
  final WatchVideoProgressUseCase _watchProgress;
  final Stream<void> _appResumed;
  final DateTime Function() _clock;
  final Duration resumeScanInterval;
  final Stream<bool> _playbackActive;

  StreamSubscription<bool>? _playback;

  /// Whether a video is open now (playing, paused, in the small window).
  final bool Function() _isPlaybackActive;
  static bool _never() => false;

  /// An automatic sync was due while a video was open: runs once it closes.
  bool _deferred = false;

  StreamSubscription<List<Video>>? _videos;
  StreamSubscription<Map<String, VideoProgress>>? _progress;
  StreamSubscription<void>? _resumed;
  DateTime? _lastScan;

  /// Shows the saved videos and checks the device. Safe to call twice.
  Future<void> start() async {
    if (_videos != null) return;
    _videos = _watchVideos().listen((videos) {
      if (!isClosed) emit(state.copyWith(videos: videos));
    });
    // Separate from the videos: progress saved while one plays doesn't
    // reload the library.
    _progress = _watchProgress().listen((progress) {
      if (!isClosed) emit(state.copyWith(progress: progress));
    });
    _resumed = _appResumed.listen((_) => _onResumed());
    _playback = _playbackActive.listen((active) {
      if (!active && _deferred) {
        _deferred = false;
        unawaited(_autoSync());
      }
    });
    await _checkAndScan();
  }

  /// The sync running now (automatic or the Scan button's); null if none.
  /// Kept apart from [VideoLibraryState.isScanning], which is only the
  /// spinner: automatic checks run without one.
  Future<Either<Failure, VideoLibraryChanges>>? _running;

  /// The Scan button's scan is waiting or running.
  bool _forcing = false;

  /// The Scan button: reads every video on the device, now (even while a
  /// video plays: the user asked). Returns what changed (or why it
  /// failed); null if a scan was already running.
  Future<Either<Failure, VideoLibraryChanges>?> scan() async {
    if (_forcing || isClosed) return null;
    _forcing = true;
    emit(state.copyWith(isScanning: true)); // answers the tap at once
    try {
      // A silent check may be running: it can't be stopped, so let it
      // finish, then read everything.
      await _running;
      if (isClosed) return null;
      return await _run(force: true);
    } finally {
      _forcing = false;
    }
  }

  /// An automatic sync: a cheap check first (see the class doc), never
  /// while a video is open, and never on top of another sync.
  Future<void> _autoSync() async {
    if (_isPlaybackActive()) {
      _deferred = true;
      return;
    }
    if (_running != null || _forcing || isClosed) return;
    await _run(force: false);
  }

  Future<Either<Failure, VideoLibraryChanges>> _run({
    required bool force,
  }) async {
    // The spinner is for the Scan button, or for a library with nothing to
    // show yet (better than "no videos" while the first scan reads). A
    // routine check (two tiny queries) stays silent: if it finds changes,
    // the list updates by itself.
    if ((force || state.videos.isEmpty) && !state.isScanning) {
      emit(state.copyWith(isScanning: true));
    }
    final running = _running = _sync(VideoSyncParams(force: force));
    final Either<Failure, VideoLibraryChanges> result;
    try {
      result = await running;
    } finally {
      _running = null;
    }
    _lastScan = _clock();
    if (isClosed) return result;
    // A Scan tap waiting for this check keeps its spinner.
    final isScanning = !force && _forcing;
    final failure = result.fold((f) => f, (_) => null);
    if (failure is PermissionFailure) {
      emit(
        state.copyWith(
          isScanning: isScanning,
          status: VideoLibraryStatus.permissionRequired,
          permission: failure.permanentlyDenied
              ? LibraryPermission.permanentlyDenied
              : LibraryPermission.denied,
        ),
      );
    } else {
      emit(state.copyWith(isScanning: isScanning));
    }
    return result;
  }

  /// Shows the system dialog (from the user's tap), then scans if allowed.
  Future<void> requestPermission() async {
    final permission = await _requestPermission();
    if (isClosed) return;
    await _apply(permission);
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
    await _autoSync();
  }

  void _onResumed() {
    if (state.status == VideoLibraryStatus.permissionRequired) {
      unawaited(_checkAndScan());
      return;
    }
    final last = _lastScan;
    if (last == null || _clock().difference(last) >= resumeScanInterval) {
      unawaited(_autoSync());
    }
  }

  @override
  Future<void> close() async {
    await _videos?.cancel();
    await _progress?.cancel();
    await _resumed?.cancel();
    await _playback?.cancel();
    return super.close();
  }
}
