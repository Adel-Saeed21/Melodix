import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/service/app_lifecycle_service.dart';
import 'package:melodix/core/usecase/usecase.dart';
import 'package:melodix/features/music_library/domain/entities/library_permission.dart';
import 'package:melodix/features/music_library/domain/entities/library_sync_result.dart';
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

class MockCheck extends Mock implements CheckLibraryPermissionUseCase {}

class MockRequest extends Mock implements RequestLibraryPermissionUseCase {}

class MockSync extends Mock implements SyncMusicLibraryUseCase {}

class MockLastSync extends Mock implements GetLastLibrarySyncUseCase {}

class MockWatch extends Mock implements WatchLibrarySongsUseCase {}

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
  setUpAll(() => registerFallbackValue(const NoParams()));

  late MockCheck check;
  late MockRequest request;
  late MockSync sync;
  late MockLastSync lastSync;
  late MockWatch watch;
  late FakeLifecycle lifecycle;
  late StreamController<List<Song>> songs;

  /// Like Isar's `watch(fireImmediately: true)`: emits [initial] as soon as
  /// someone listens, then every later change.
  void savedLibrary(List<Song> initial) {
    when(() => watch()).thenAnswer(
      (_) => Stream.multi((controller) {
        controller.addSync(initial);
        final sub = songs.stream.listen(controller.add);
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
    when(() => watch()).thenAnswer((_) => songs.stream);
    when(() => sync(any())).thenAnswer((_) async => Right(_syncResult));
  });

  tearDown(() async {
    await songs.close();
    await lifecycle.controller.close();
  });

  MusicLibraryBloc build({Duration interval = const Duration(minutes: 10)}) =>
      MusicLibraryBloc(
        checkPermission: check,
        requestPermission: request,
        syncLibrary: sync,
        getLastSync: lastSync,
        watchSongs: watch,
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
    expect(bloc.state.lastSyncResult, _syncResult);
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
}
