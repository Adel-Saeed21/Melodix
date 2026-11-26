import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/entities/library_permission.dart';
import 'package:melodix/core/usecase/open_app_settings_usecase.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/domain/entities/video_library_changes.dart';
import 'package:melodix/features/video/domain/usecases/sync_video_library_usecase.dart';
import 'package:melodix/features/video/domain/entities/video_progress.dart';
import 'package:melodix/features/video/domain/usecases/video_progress_usecases.dart';
import 'package:melodix/features/video/domain/usecases/video_permission_usecases.dart';
import 'package:melodix/features/video/domain/usecases/watch_videos_usecase.dart';
import 'package:melodix/features/video/presentation/logic/video_library_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../video_fixtures.dart';

class MockWatchVideos extends Mock implements WatchVideosUseCase {}

class MockSync extends Mock implements SyncVideoLibraryUseCase {}

class MockCheck extends Mock implements CheckVideoPermissionUseCase {}

class MockRequest extends Mock implements RequestVideoPermissionUseCase {}

class MockOpenSettings extends Mock implements OpenAppSettingsUseCase {}

class MockWatchProgress extends Mock implements WatchVideoProgressUseCase {}

const _noChanges = VideoLibraryChanges(
  added: 0,
  updated: 0,
  removed: 0,
  total: 0,
);

void main() {
  late MockWatchVideos watch;
  late MockSync sync;
  late MockCheck check;
  late MockRequest request;
  late StreamController<List<Video>> videos;
  late StreamController<Map<String, VideoProgress>> progress;
  late StreamController<void> resumed;
  late DateTime now;

  /// Whether a video is open (the app's video session).
  late StreamController<bool> playing;
  var videoOpen = false;

  /// Opens / closes "the video" (as the session would report it).
  Future<void> setVideoOpen(bool open) async {
    videoOpen = open;
    playing.add(open);
    await pumpEventQueue();
  }

  setUpAll(() => registerFallbackValue(const VideoSyncParams()));

  setUp(() {
    watch = MockWatchVideos();
    sync = MockSync();
    check = MockCheck();
    request = MockRequest();
    videos = StreamController<List<Video>>.broadcast();
    progress = StreamController<Map<String, VideoProgress>>.broadcast();
    resumed = StreamController<void>.broadcast();
    now = DateTime(2026, 1, 1, 12);
    playing = StreamController<bool>.broadcast();
    videoOpen = false;
    when(() => watch()).thenAnswer((_) => videos.stream);
    when(() => sync(any())).thenAnswer((_) async => const Right(_noChanges));
    when(() => check()).thenAnswer((_) async => LibraryPermission.granted);
  });

  tearDown(() async {
    await videos.close();
    await progress.close();
    await resumed.close();
    await playing.close();
  });

  VideoLibraryCubit build() {
    final watchProgress = MockWatchProgress();
    when(() => watchProgress()).thenAnswer((_) => progress.stream);
    return VideoLibraryCubit(
      watchVideos: watch,
      sync: sync,
      checkPermission: check,
      requestPermission: request,
      openSettings: MockOpenSettings(),
      watchProgress: watchProgress,
      appResumed: resumed.stream,
      isPlaybackActive: () => videoOpen,
      playbackActive: playing.stream,
      clock: () => now,
    );
  }

  test('shows the saved videos, then scans behind them', () async {
    final cubit = build();
    final started = cubit.start();
    videos.add([testVideo('a')]);
    await started;

    expect(cubit.state.status, VideoLibraryStatus.ready);
    expect(cubit.state.videos.single.id, 'a');
    verify(() => sync(any())).called(1);
    verifyNever(() => request());
    await cubit.close();
  });

  test('without access: asks nothing, scans nothing until tapped', () async {
    when(() => check()).thenAnswer((_) async => LibraryPermission.denied);
    final cubit = build();
    await cubit.start();

    expect(cubit.state.status, VideoLibraryStatus.permissionRequired);
    verifyNever(() => request());
    verifyNever(() => sync(any()));

    when(() => request()).thenAnswer((_) async => LibraryPermission.granted);
    await cubit.requestPermission();
    expect(cubit.state.status, VideoLibraryStatus.ready);
    verify(() => sync(any())).called(1);
    await cubit.close();
  });

  test('access granted in the settings: noticed on return', () async {
    when(() => check())
        .thenAnswer((_) async => LibraryPermission.permanentlyDenied);
    final cubit = build();
    await cubit.start();
    expect(cubit.state.permission, LibraryPermission.permanentlyDenied);

    when(() => check()).thenAnswer((_) async => LibraryPermission.granted);
    resumed.add(null);
    await pumpEventQueue();
    expect(cubit.state.status, VideoLibraryStatus.ready);
    verify(() => sync(any())).called(1);
    await cubit.close();
  });

  test('returning to the app checks at most every 15 seconds', () async {
    final cubit = build();
    await cubit.start();
    clearInteractions(sync);

    resumed.add(null);
    await pumpEventQueue();
    verifyNever(() => sync(any()));

    now = now.add(const Duration(seconds: 20));
    resumed.add(null);
    await pumpEventQueue();
    verify(() => sync(any())).called(1);
    await cubit.close();
  });

  test('automatic syncs are cheap checks; the Scan button reads all', () async {
    final cubit = build();
    await cubit.start();
    verify(() => sync(const VideoSyncParams())).called(1);

    await cubit.scan();
    verify(() => sync(const VideoSyncParams(force: true))).called(1);
    await cubit.close();
  });

  group('while a video is open', () {
    test('opening the tab waits, then syncs once the video closes', () async {
      final cubit = build();
      videoOpen = true; // already open when the tab opens
      await cubit.start();
      await pumpEventQueue();
      // The saved videos show; the device isn't read during playback.
      expect(cubit.state.status, VideoLibraryStatus.ready);
      verifyNever(() => sync(any()));

      await setVideoOpen(false);
      verify(() => sync(const VideoSyncParams())).called(1);
      await cubit.close();
    });

    test(
      'returning to the app waits too (once, however many returns)',
      () async {
        final cubit = build();
        await cubit.start();
        clearInteractions(sync);
        await setVideoOpen(true);

        for (var i = 0; i < 3; i++) {
          now = now.add(const Duration(minutes: 1));
          resumed.add(null);
          await pumpEventQueue();
        }
        verifyNever(() => sync(any()));

        await setVideoOpen(false);
        verify(() => sync(any())).called(1);
        await cubit.close();
      },
    );

    test('the Scan button still works (the user asked)', () async {
      final cubit = build();
      await cubit.start();
      clearInteractions(sync);
      await setVideoOpen(true);

      await cubit.scan();
      verify(() => sync(const VideoSyncParams(force: true))).called(1);
      await cubit.close();
    });
  });

  test('a scan losing access shows the permission page', () async {
    final cubit = build();
    await cubit.start();
    when(() => sync(any())).thenAnswer(
      (_) async =>
          const Left(PermissionFailure('no', permanentlyDenied: false)),
    );

    await cubit.scan();
    expect(cubit.state.status, VideoLibraryStatus.permissionRequired);
    expect(cubit.state.isScanning, isFalse);
    await cubit.close();
  });

  test('a scan tapped while one runs does nothing', () async {
    final gate = Completer<Either<Failure, VideoLibraryChanges>>();
    final cubit = build();
    await cubit.start();
    when(() => sync(any())).thenAnswer((_) => gate.future);

    final first = cubit.scan();
    expect(await cubit.scan(), isNull);
    gate.complete(const Right(_noChanges));
    await first;
    verify(() => sync(any())).called(2); // start + first
    await cubit.close();
  });

  test('continue watching: started videos, most recent first', () async {
    final cubit = build();
    final started = cubit.start();
    videos.add([
      testVideo('new'),
      testVideo('old'),
      testVideo('recent'),
      testVideo('done'),
    ]);
    progress.add({
      'old': watched(
        'old',
        const Duration(minutes: 1),
        at: DateTime(2026, 1, 1),
      ),
      'recent': watched(
        'recent',
        const Duration(minutes: 2),
        at: DateTime(2026, 1, 5),
      ),
      // Within 10 s of the end: watched, not "continue".
      'done': watched(
        'done',
        const Duration(minutes: 9, seconds: 55),
        at: DateTime(2026, 1, 9),
      ),
    });
    await started;
    await pumpEventQueue();
    expect(cubit.state.continueWatching.map((v) => v.id), ['recent', 'old']);
    await cubit.close();
  });

  test('progress changes never reload the videos list', () async {
    final cubit = build();
    final started = cubit.start();
    final list = [testVideo('a')];
    videos.add(list);
    await started;
    await pumpEventQueue();

    progress.add({'a': watched('a', const Duration(minutes: 1))});
    await pumpEventQueue();
    // Same list object: nothing showing it needs rebuilding.
    expect(cubit.state.videos, same(list));
    expect(cubit.state.progress['a']!.position, const Duration(minutes: 1));
    await cubit.close();
  });
}
