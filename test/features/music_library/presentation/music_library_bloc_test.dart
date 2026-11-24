import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/service/app_lifecycle_service.dart';
import 'package:melodix/core/entities/library_permission.dart';
import 'package:melodix/features/music_library/domain/entities/library_sync_result.dart';
import 'package:melodix/features/music_library/domain/entities/library_update.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/usecases/check_library_permission_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_last_library_sync_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/open_library_settings_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/request_library_permission_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/sync_music_library_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_library_songs_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_event.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_state.dart';
import 'package:mocktail/mocktail.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_library_sync_stage_usecase.dart';
import 'package:melodix/features/music_library/domain/entities/library_sync_stage.dart';

class MockCheck extends Mock implements CheckLibraryPermissionUseCase {}

class MockRequest extends Mock implements RequestLibraryPermissionUseCase {}

class MockSync extends Mock implements SyncMusicLibraryUseCase {}

class MockLastSync extends Mock implements GetLastLibrarySyncUseCase {}

class MockWatch extends Mock implements WatchLibrarySongsUseCase {}

class MockWatchStage extends Mock implements WatchLibrarySyncStageUseCase {}

class MockOpenSettings extends Mock implements OpenLibrarySettingsUseCase {}

class FakeLifecycle implements AppLifecycleService {
  final controller = StreamController<void>.broadcast();

  @override
  Stream<void> get onResumed => controller.stream;
}

final _song = Song(
  id: 1,
  title: 'Song',
  artist: 'Artist',
  album: 'Album',
  albumId: 1,
  duration: const Duration(minutes: 3),
  path: '/music/1.mp3',
  playbackUri: Uri.parse('content://media/external/audio/media/1'),
  isFavorite: false,
  playCount: 0,
);

final _syncResult = LibrarySyncResult(
  added: 1,
  updated: 0,
  removed: 0,
  total: 1,
  syncedAt: DateTime(2026, 11, 22),
);

void main() {
  setUpAll(() => registerFallbackValue(const SyncLibraryParams()));

  late MockCheck check;
  late MockRequest request;
  late MockSync sync;
  late MockLastSync lastSync;
  late MockWatch watch;
  late FakeLifecycle lifecycle;
  late StreamController<List<Song>> songs;
  late StreamController<LibrarySyncStage> stages;
  late MockWatchStage watchStage;

  /// Like Isar's `watch(fireImmediately: true)`: emits [initial] as soon as
  /// someone listens, then every later change.
  void savedLibrary(List<Song> initial) {
    when(() => watch()).thenAnswer(
      (_) => Stream.multi((controller) {
        controller.addSync(LibraryReloaded(initial));
        final sub = songs.stream.listen(
          (list) => controller.add(LibraryReloaded(list)),
        );
        controller.onCancel = sub.cancel;
      }),
    );
  }

  setUp(() {
    check = MockCheck();
    request = MockRequest();
    sync = MockSync();
    lastSync = MockLastSync();
    watch = MockWatch();
    lifecycle = FakeLifecycle();
    songs = StreamController<List<Song>>.broadcast();
    stages = StreamController<LibrarySyncStage>.broadcast();
    watchStage = MockWatchStage();
    when(() => watchStage()).thenAnswer((_) => stages.stream);
    when(
      () => watch(),
    ).thenAnswer((_) => songs.stream.map<LibraryUpdate>(LibraryReloaded.new));
    when(() => sync(any())).thenAnswer((_) async => Right(_syncResult));
  });

  tearDown(() async {
    await songs.close();
    await stages.close();
    await lifecycle.controller.close();
  });

  MusicLibraryBloc build({Duration interval = const Duration(minutes: 10)}) =>
      MusicLibraryBloc(
        checkPermission: check,
        requestPermission: request,
        syncLibrary: sync,
        getLastSync: lastSync,
        watchSongs: watch,
        watchSyncStage: watchStage,
        lifecycle: lifecycle,
        openSettings: MockOpenSettings(),
        resumeSyncInterval: interval,
      );

  /// Lets queued events and async handlers finish.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('first launch without access waits for permission, no scan', () async {
    when(() => lastSync()).thenAnswer((_) async => null);
    when(() => check()).thenAnswer((_) async => LibraryPermission.denied);
    final bloc = build()..add(const MusicLibraryStarted());
    await settle();

    expect(bloc.state.status, MusicLibraryStatus.permissionRequired);
    verifyNever(() => sync(any()));
    verifyNever(() => request());
    await bloc.close();
  });

  test('granting access on first launch runs the initial scan', () async {
    when(() => lastSync()).thenAnswer((_) async => null);
    when(() => check()).thenAnswer((_) async => LibraryPermission.denied);
    when(() => request()).thenAnswer((_) async => LibraryPermission.granted);
    final bloc = build()..add(const MusicLibraryStarted());
    await settle();

    final statuses = <MusicLibraryStatus>[];
    final sub = bloc.stream.listen((s) => statuses.add(s.status));
    bloc.add(const MusicLibraryPermissionRequested());
    await settle();

    expect(statuses, contains(MusicLibraryStatus.scanning));
    expect(bloc.state.status, MusicLibraryStatus.ready);
    expect(bloc.state.isSyncing, isFalse);
    await sub.cancel();
    await bloc.close();
  });

  test(
    'startup with saved library shows songs and syncs in background',
    () async {
      when(() => lastSync()).thenAnswer((_) async => DateTime(2026, 11, 1));
      when(() => check()).thenAnswer((_) async => LibraryPermission.granted);
      savedLibrary([_song]);
      final bloc = build()..add(const MusicLibraryStarted());
      await settle();

      expect(bloc.state.status, MusicLibraryStatus.ready);
      expect(bloc.state.songs, [_song]);
      verify(() => sync(any())).called(1);
      verifyNever(() => request());
      await bloc.close();
    },
  );

  test('a failed refresh keeps the existing songs', () async {
    when(() => lastSync()).thenAnswer((_) async => DateTime(2026, 11, 1));
    when(() => check()).thenAnswer((_) async => LibraryPermission.granted);
    when(() => sync(any()))
        .thenAnswer((_) async => const Left(LibraryFailure('oops')));
    savedLibrary([_song]);
    final bloc = build()..add(const MusicLibraryStarted());
    await settle();

    expect(bloc.state.status, MusicLibraryStatus.ready);
    expect(bloc.state.songs, [_song]);
    expect(bloc.state.errorMessage, 'oops');
    await bloc.close();
  });

  test('resuming after granting access in settings syncs', () async {
    when(() => lastSync()).thenAnswer((_) async => null);
    when(() => check()).thenAnswer((_) async => LibraryPermission.denied);
    final bloc = build()..add(const MusicLibraryStarted());
    await settle();
    verifyNever(() => sync(any()));

    when(() => check()).thenAnswer((_) async => LibraryPermission.granted);
    lifecycle.controller.add(null);
    await settle();
    await settle();

    verify(() => sync(any())).called(1);
    expect(bloc.state.status, MusicLibraryStatus.ready);
    await bloc.close();
  });

  test('resuming after access was revoked asks for permission', () async {
    when(() => lastSync()).thenAnswer((_) async => DateTime.now());
    when(() => check()).thenAnswer((_) async => LibraryPermission.granted);
    final bloc = build()..add(const MusicLibraryStarted());
    await settle();

    when(() => check())
        .thenAnswer((_) async => LibraryPermission.permanentlyDenied);
    lifecycle.controller.add(null);
    await settle();
    await settle();

    expect(bloc.state.status, MusicLibraryStatus.permissionRequired);
    expect(bloc.state.permission, LibraryPermission.permanentlyDenied);
    await bloc.close();
  });

  test('resuming soon after a sync does not rescan', () async {
    when(() => lastSync()).thenAnswer((_) async => DateTime(2026, 11, 1));
    when(() => check()).thenAnswer((_) async => LibraryPermission.granted);
    when(() => sync(any())).thenAnswer(
      (_) async => Right(
        LibrarySyncResult(
          added: 0,
          updated: 0,
          removed: 0,
          total: 0,
          syncedAt: DateTime.now(),
        ),
      ),
    );
    final bloc = build()..add(const MusicLibraryStarted());
    await settle();
    verify(() => sync(any())).called(1);

    lifecycle.controller.add(null);
    await settle();
    await settle();

    verifyNever(() => sync(any()));
    await bloc.close();
  });

  test('manual refresh rescans', () async {
    when(() => lastSync()).thenAnswer((_) async => DateTime.now());
    when(() => check()).thenAnswer((_) async => LibraryPermission.granted);
    final bloc = build()..add(const MusicLibraryStarted());
    await settle();
    clearInteractions(sync);

    bloc.add(const MusicLibraryRefreshRequested());
    await settle();

    verify(() => sync(any())).called(1);
    await bloc.close();
  });

  test(
    'a scan only looks for changes; a full re-read must be asked for',
    () async {
      when(() => lastSync()).thenAnswer((_) async => DateTime.now());
      when(() => check()).thenAnswer((_) async => LibraryPermission.granted);
      final bloc = build()..add(const MusicLibraryStarted());
      await settle();
      final startup =
          verify(() => sync(captureAny())).captured.single as SyncLibraryParams;
      expect(startup.force, isFalse);

      // The Scan button: changes only (never a full re-read by accident).
      bloc.add(const MusicLibraryRefreshRequested());
      await settle();
      final scan =
          verify(() => sync(captureAny())).captured.single as SyncLibraryParams;
      expect(scan.force, isFalse);

      // Explicitly asked for: everything is read again.
      bloc.add(const MusicLibraryRefreshRequested(full: true));
      await settle();
      final full =
          verify(() => sync(captureAny())).captured.single as SyncLibraryParams;
      expect(full.force, isTrue);
      await bloc.close();
    },
  );

  test(
    'a full re-read asked for during a background sync still runs',
    () async {
      when(() => lastSync()).thenAnswer((_) async => DateTime.now());
      when(() => check()).thenAnswer((_) async => LibraryPermission.granted);
      final background = Completer<Either<Failure, LibrarySyncResult>>();
      final forced = Completer<Either<Failure, LibrarySyncResult>>();
      when(() => sync(any())).thenAnswer(
        (invocation) =>
            (invocation.positionalArguments.single as SyncLibraryParams).force
            ? forced.future
            : background.future,
      );
      final bloc = build()..add(const MusicLibraryStarted());
      await settle();
      expect(bloc.state.isSyncing, isTrue);

      bloc.add(const MusicLibraryRefreshRequested(full: true));
      // A second request while it waits adds no extra scan.
      bloc.add(const MusicLibraryRefreshRequested(full: true));
      await settle();
      final forces = verify(() => sync(captureAny())).captured
          .cast<SyncLibraryParams>()
          .map((p) => p.force);
      expect(forces, [false, true]);

      // The background sync ends first: still syncing (the rescan runs).
      background.complete(Right(_syncResult));
      await settle();
      expect(bloc.state.isSyncing, isTrue);

      forced.complete(Right(_syncResult));
      await settle();
      expect(bloc.state.isSyncing, isFalse);
      expect(bloc.state.status, MusicLibraryStatus.ready);
      await bloc.close();
    },
  );

  test('a library stream error is reported, not thrown', () async {
    when(() => lastSync()).thenAnswer((_) async => DateTime.now());
    when(() => check()).thenAnswer((_) async => LibraryPermission.granted);
    final updates = StreamController<LibraryUpdate>();
    when(() => watch()).thenAnswer((_) => updates.stream);
    final bloc = build()..add(const MusicLibraryStarted());
    await settle();
    updates.add(LibraryReloaded([_song]));
    await settle();

    final errors = <Object>[];
    final sub = bloc.stream.listen(null, onError: errors.add);
    updates.addError(StateError('read failed'));
    await settle();

    // Songs already shown stay; later updates still arrive.
    expect(bloc.state.songs, [_song]);
    updates.add(const LibraryReloaded([]));
    await settle();
    expect(bloc.state.songs, isEmpty);
    expect(errors, isEmpty);
    await sub.cancel();
    await updates.close();
    await bloc.close();
  });

  test(
    'the running sync\'s stage is kept, then cleared when it ends',
    () async {
      when(() => lastSync()).thenAnswer((_) async => DateTime.now());
      when(() => check()).thenAnswer((_) async => LibraryPermission.granted);
      final done = Completer<Either<Failure, LibrarySyncResult>>();
      when(() => sync(any())).thenAnswer((_) => done.future);
      final bloc = build()..add(const MusicLibraryStarted());
      await settle();

      stages.add(LibrarySyncStage.checking);
      await settle();
      expect(bloc.state.syncStage, LibrarySyncStage.checking);
      stages.add(LibrarySyncStage.reading);
      await settle();
      expect(bloc.state.syncStage, LibrarySyncStage.reading);

      done.complete(Right(_syncResult));
      await settle();
      expect(bloc.state.isSyncing, isFalse);
      expect(bloc.state.syncStage, isNull);
      expect(bloc.state.lastSyncResult, _syncResult);

      // A late stage can't bring back a finished sync's progress.
      stages.add(LibrarySyncStage.saving);
      await settle();
      expect(bloc.state.syncStage, isNull);
      await bloc.close();
    },
  );

  test('a scan while one is running adds no second scan', () async {
    when(() => lastSync()).thenAnswer((_) async => DateTime.now());
    when(() => check()).thenAnswer((_) async => LibraryPermission.granted);
    final running = Completer<Either<Failure, LibrarySyncResult>>();
    when(() => sync(any())).thenAnswer((_) => running.future);
    final bloc = build()..add(const MusicLibraryStarted());
    await settle();

    bloc.add(const MusicLibraryRefreshRequested());
    await settle();

    verify(() => sync(any())).called(1); // only the startup one
    running.complete(Right(_syncResult));
    await settle();
    await bloc.close();
  });
}
