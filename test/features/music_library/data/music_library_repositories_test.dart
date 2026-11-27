import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/database/collections/playlist_collection.dart';
import 'package:melodix/features/music_library/data/datasources/music_local_storage.dart';
import 'package:melodix/features/music_library/data/datasources/song_library_update.dart';
import 'package:melodix/features/music_library/data/datasources/playlist_local_storage.dart';
import 'package:melodix/core/errors/exceptions.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/features/music_library/data/models/local_song.dart';
import 'package:melodix/features/music_library/data/datasources/audio_library_delta_source.dart';
import 'package:melodix/features/music_library/data/datasources/music_service.dart';
import 'package:melodix/core/service/permission_handling_service.dart';
import 'package:melodix/features/music_library/data/mappers/song_mapper.dart';
import 'package:melodix/features/music_library/data/repositories/artwork_repository_impl.dart';
import 'package:melodix/features/music_library/data/repositories/library_permission_repository_impl.dart';
import 'package:melodix/features/music_library/data/repositories/library_sync_repository_impl.dart';
import 'package:melodix/features/music_library/data/repositories/playlist_repository_impl.dart';
import 'package:melodix/features/music_library/data/repositories/song_repository_impl.dart';
import 'package:melodix/features/music_library/data/sync/full_library_scan.dart';
import 'package:melodix/features/music_library/data/sync/incremental_library_scan.dart';
import 'package:melodix/core/entities/library_permission.dart';
import 'package:melodix/features/music_library/domain/entities/library_update.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures.dart';

class MockMusicService extends Mock implements MusicService {}

class MockMusicLocalStorage extends Mock implements MusicLocalStorage {}

class MockPermissionService extends Mock implements PermissionHandlingService {}

class MockPlaylistStorage extends Mock implements PlaylistLocalStorage {}

class MockDeltaSource extends Mock implements AudioLibraryDeltaSource {}

void main() {
  late MockMusicService musicService;
  late MockMusicLocalStorage storage;
  late MockPermissionService permissions;
  late MockPlaylistStorage playlists;
  late MockDeltaSource deltaSource;
  late LibrarySyncRepositoryImpl syncRepo;
  late SongRepositoryImpl songRepo;
  late PlaylistRepositoryImpl playlistRepo;
  late ArtworkRepositoryImpl artwork;
  late LibraryPermissionRepositoryImpl permissionRepo;
  final syncedAt = DateTime(2026, 11, 22, 10);

  setUp(() {
    musicService = MockMusicService();
    storage = MockMusicLocalStorage();
    permissions = MockPermissionService();
    playlists = MockPlaylistStorage();
    deltaSource = MockDeltaSource();
    const mapper = SongMapper(isAndroid: true);
    syncRepo = LibrarySyncRepositoryImpl(
      permissionService: permissions,
      deltaSource: deltaSource,
      storage: storage,
      fullScan: FullLibraryScan(
        musicService: musicService,
        deltaSource: deltaSource,
        storage: storage,
      ),
      incrementalScan: IncrementalLibraryScan(
        deltaSource: deltaSource,
        storage: storage,
      ),
    );
    songRepo = SongRepositoryImpl(
      storage: storage,
      musicService: musicService,
      mapper: mapper,
    );
    playlistRepo = PlaylistRepositoryImpl(storage: playlists, mapper: mapper);
    artwork = ArtworkRepositoryImpl(musicService);
    permissionRepo = LibraryPermissionRepositoryImpl(permissions);
    registerFallbackValue(<LocalSong>[]);
    registerFallbackValue(<int>[]);
    // By default: permission granted, the device has no generations and no
    // native scan, so syncs are full scans through MusicService.
    when(() => permissions.audioStatus())
        .thenAnswer((_) async => MediaPermissionStatus.granted);
    when(() => deltaSource.currentCheckpoint()).thenAnswer((_) async => null);
    when(() => deltaSource.fullScan()).thenAnswer((_) async => null);
    when(() => storage.getAllSongIds()).thenAnswer((_) async => <int>{});
    when(() => storage.getSyncCheckpoint()).thenAnswer((_) async => null);
    when(() => storage.getLastSyncedAt()).thenAnswer((_) async => syncedAt);
  });

  group('syncLibrary', () {
    test('scans, saves and reports what changed', () async {
      final scanned = [localSong(1), localSong(2)];
      when(() => musicService.getAllSongs()).thenAnswer((_) async => scanned);
      when(
        () => storage.syncSongs(scanned, checkpoint: any(named: 'checkpoint')),
      ).thenAnswer(
        (_) async =>
            const SongSyncResult(added: 1, updated: 1, removed: 3, total: 2),
      );

      final result = await syncRepo.syncLibrary();

      final sync = result.getOrElse(() => throw StateError('expected Right'));
      expect(sync.added, 1);
      expect(sync.updated, 1);
      expect(sync.removed, 3);
      expect(sync.total, 2);
      expect(sync.syncedAt, syncedAt);
    });

    test('maps a permission error to PermissionFailure', () async {
      when(() => musicService.getAllSongs())
          .thenThrow(const MediaPermissionException(permanentlyDenied: true));

      final result = await syncRepo.syncLibrary();

      final failure = result.swap().getOrElse(() => throw StateError('Left'));
      expect(failure, isA<PermissionFailure>());
      expect((failure as PermissionFailure).permanentlyDenied, isTrue);
      verifyNever(
        () => storage.syncSongs(any(), checkpoint: any(named: 'checkpoint')),
      );
    });

    test(
      'checks permission without a dialog and stops before reading',
      () async {
        when(() => permissions.audioStatus())
            .thenAnswer((_) async => MediaPermissionStatus.denied);

        final result = await syncRepo.syncLibrary();

        final failure = result.swap().getOrElse(() => throw StateError('Left'));
        expect(failure, isA<PermissionFailure>());
        verifyNever(() => permissions.requestAudio());
        verifyNever(() => deltaSource.currentCheckpoint());
        verifyNever(() => musicService.getAllSongs());
        verifyNever(
          () => storage.syncSongs(any(), checkpoint: any(named: 'checkpoint')),
        );
      },
    );

    test('an unconfirmed empty scan never wipes the library', () async {
      when(() => musicService.getAllSongs()).thenAnswer((_) async => []);
      when(() => storage.getAllSongIds()).thenAnswer((_) async => {1, 2});

      final result = await syncRepo.syncLibrary();

      result.fold(
        (f) => expect(f, isA<LibraryFailure>()),
        (_) => fail('expected a failure'),
      );
      verifyNever(
        () => storage.syncSongs(any(), checkpoint: any(named: 'checkpoint')),
      );
    });

    test('maps other errors to LibraryFailure', () async {
      when(() => musicService.getAllSongs()).thenThrow(Exception('boom'));

      final result = await syncRepo.syncLibrary();

      expect(result.isLeft(), isTrue);
      result.leftMap((f) => expect(f, isA<LibraryFailure>()));
    });

    test('concurrent calls share a single scan', () async {
      final scan = Completer<List<LocalSong>>();
      when(() => musicService.getAllSongs()).thenAnswer((_) => scan.future);
      when(
        () => storage.syncSongs(any(), checkpoint: any(named: 'checkpoint')),
      ).thenAnswer(
        (_) async =>
            const SongSyncResult(added: 0, updated: 0, removed: 0, total: 0),
      );

      final first = syncRepo.syncLibrary();
      final second = syncRepo.syncLibrary();
      scan.complete(const []);
      await Future.wait([first, second]);

      verify(() => musicService.getAllSongs()).called(1);

      // A later call starts a new scan.
      await syncRepo.syncLibrary();
      verify(() => musicService.getAllSongs()).called(1);
    });
  });

  test('artwork that failed (e.g. no permission) is retried later', () async {
    var calls = 0;
    when(() => musicService.getArtwork(5, size: 200)).thenAnswer((_) async {
      calls++;
      if (calls == 1) {
        throw const MediaPermissionException(permanentlyDenied: false);
      }
      return Uint8List.fromList([1, 2, 3]);
    });

    expect(await artwork.getArtwork(5), isNull);
    expect(await artwork.getArtwork(5), [1, 2, 3]);
    expect(await artwork.getArtwork(5), [1, 2, 3]); // now cached
    expect(calls, 2);
  });

  test('cached artwork comes back synchronously', () async {
    when(() => musicService.getArtwork(5, size: 200))
        .thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));

    expect(artwork.getArtwork(5), isA<Future<Uint8List?>>());
    await artwork.getArtwork(5);

    // Cached: a plain value, so a widget can show it in the same frame.
    expect(artwork.getArtwork(5), [1, 2, 3]);
  });

  test('concurrent requests for one cover share a single load', () async {
    final pending = Completer<Uint8List?>();
    when(() => musicService.getArtwork(5, size: 200))
        .thenAnswer((_) => pending.future);

    final first = artwork.getArtwork(5);
    final second = artwork.getArtwork(5);
    pending.complete(Uint8List.fromList([7]));

    expect(await first, [7]);
    expect(await second, [7]);
    verify(() => musicService.getArtwork(5, size: 200)).called(1);
  });

  test('checkPermission maps the platform status', () async {
    when(() => permissions.audioStatus())
        .thenAnswer((_) async => MediaPermissionStatus.permanentlyDenied);

    expect(
      await permissionRepo.checkPermission(),
      LibraryPermission.permanentlyDenied,
    );
  });

  test('watchLibrary maps storage updates to domain updates', () async {
    when(() => storage.watchLibrary()).thenAnswer(
      (_) => Stream.fromIterable([
        SongLibraryLoaded([songRow(4)]),
        SongLibrarySongsChanged([songRow(4)..playCount = 2]),
        const SongLibrarySongsRemoved({4}),
      ]),
    );

    final updates = await songRepo.watchLibrary().toList();

    expect(updates[1], isA<LibrarySongsUpdated>());
    expect((updates[1] as LibrarySongsUpdated).songs.single.playCount, 2);
    expect((updates[2] as LibrarySongsRemoved).ids, {4});
    final songs = (updates[0] as LibraryReloaded).songs;

    expect(songs.single.id, 4);
    expect(
      songs.single.playbackUri.toString(),
      'content://media/external/audio/media/4',
    );
  });

  test('read errors become LibraryFailure', () async {
    when(() => playlists.getPlaylistSongs(4)).thenThrow(Exception('db'));

    final result = await playlistRepo.getPlaylistSongs(4);

    result.fold(
      (f) => expect(f, isA<LibraryFailure>()),
      (_) => fail('expected failure'),
    );
  });

  group('song actions', () {
    test('toggleFavorite returns the new value', () async {
      when(() => storage.toggleFavorite(4)).thenAnswer((_) async => true);

      expect((await songRepo.toggleFavorite(4)).getOrElse(() => false), isTrue);
    });

    test('bulk favourite delegates to storage', () async {
      when(() => storage.setFavoriteMany([1, 2], favorite: false))
          .thenAnswer((_) async {});

      expect(
        (await songRepo.setSongsFavorite([1, 2], favorite: false)).isRight(),
        isTrue,
      );
    });

    test('deleteSongs removes only what the device deleted', () async {
      when(() => musicService.deleteSongs([1, 2, 3]))
          .thenAnswer((_) async => [1, 3]);
      when(() => storage.removeSongs([1, 3])).thenAnswer((_) async {});

      final result = await songRepo.deleteSongs([1, 2, 3]);

      expect(result.getOrElse(() => -1), 2);
      verify(() => storage.removeSongs([1, 3])).called(1);
    });

    test('deleteSongs declined by the user removes nothing', () async {
      when(() => musicService.deleteSongs(any())).thenAnswer((_) async => []);

      final result = await songRepo.deleteSongs([1]);

      expect(result.getOrElse(() => -1), 0);
      verifyNever(() => storage.removeSongs(any()));
    });

    test('write errors become LibraryFailure', () async {
      when(() => storage.toggleFavorite(4)).thenThrow(Exception('db'));

      final result = await songRepo.toggleFavorite(4);

      result.fold(
        (f) => expect(f, isA<LibraryFailure>()),
        (_) => fail('expected failure'),
      );
    });

    test('addSongsToPlaylist returns how many were added', () async {
      when(() => playlists.addSongs(3, [1, 2])).thenAnswer((_) async => 1);

      final added = await playlistRepo.addSongsToPlaylist(3, [1, 2]);

      expect(added.getOrElse(() => -1), 1);
    });
  });

  group('playlists', () {
    test('watchPlaylists maps rows and uses the first song as cover', () async {
      final row = PlaylistCollection.create('Mix')..songIds = [8, 9];
      row.id = 4;
      when(() => playlists.watchAllPlaylists()).thenAnswer(
        (_) => Stream.value([row, PlaylistCollection.create('Empty')..id = 5]),
      );

      final result = await playlistRepo.watchPlaylists().first;

      expect(result.first.id, 4);
      expect(result.first.songCount, 2);
      expect(result.first.artworkSongId, 8);
      expect(result.last.artworkSongId, isNull);
    });

    test('watchPlaylists re-emits when the playlists change', () async {
      final rows = StreamController<List<PlaylistCollection>>();
      when(() => playlists.watchAllPlaylists()).thenAnswer((_) => rows.stream);

      final emitted = <int>[];
      final sub = playlistRepo.watchPlaylists().listen(
        (p) => emitted.add(p.single.songCount),
      );
      rows.add([
        PlaylistCollection.create('Mix')..songIds = [8],
      ]);
      await pumpEventQueue();
      rows.add([
        PlaylistCollection.create('Mix')..songIds = [8, 9],
      ]);
      await pumpEventQueue();

      expect(emitted, [1, 2]);
      await sub.cancel();
      await rows.close();
    });

    test('getPlaylists maps the saved playlists', () async {
      final row = PlaylistCollection.create('Mix')..songIds = [8, 9];
      row.id = 4;
      when(() => playlists.getAllPlaylists()).thenAnswer((_) async => [row]);

      final result = (await playlistRepo.getPlaylists()).getOrElse(() => []);

      expect(result.single.songCount, 2);
      expect(result.single.artworkSongId, 8);
    });

    test('getPlaylistSongs returns entities in order', () async {
      when(() => playlists.getPlaylistSongs(4))
          .thenAnswer((_) async => [songRow(9), songRow(8)]);

      final songs = (await playlistRepo.getPlaylistSongs(4))
          .getOrElse(() => []);

      expect(songs.map((s) => s.id), [9, 8]);
    });

    test('rename / delete / remove song delegate to storage', () async {
      when(() => playlists.renamePlaylist(4, 'New')).thenAnswer((_) async {});
      when(() => playlists.deletePlaylist(4)).thenAnswer((_) async {});
      when(() => playlists.removeSong(4, 8)).thenAnswer((_) async {});

      expect((await playlistRepo.renamePlaylist(4, 'New')).isRight(), isTrue);
      expect((await playlistRepo.deletePlaylist(4)).isRight(), isTrue);
      expect(
        (await playlistRepo.removeSongFromPlaylist(4, 8)).isRight(),
        isTrue,
      );
      verify(() => playlists.renamePlaylist(4, 'New')).called(1);
      verify(() => playlists.deletePlaylist(4)).called(1);
      verify(() => playlists.removeSong(4, 8)).called(1);
    });

    test('reorderPlaylistSongs saves the shown order', () async {
      when(() => playlists.reorderSongs(4, [3, 1, 2])).thenAnswer((_) async {});

      final result = await playlistRepo.reorderPlaylistSongs(4, [3, 1, 2]);

      expect(result.isRight(), isTrue);
      verify(() => playlists.reorderSongs(4, [3, 1, 2])).called(1);
    });

    test('togglePlaylistFavorite returns the new value', () async {
      when(() => playlists.toggleFavorite(4)).thenAnswer((_) async => true);

      final result = await playlistRepo.togglePlaylistFavorite(4);

      expect(result.getOrElse(() => false), isTrue);
    });
  });

  test('a forced sync waits for a running one, then scans', () async {
    final scan = Completer<List<LocalSong>>();
    var calls = 0;
    when(() => musicService.getAllSongs()).thenAnswer((_) {
      calls++;
      return calls == 1 ? scan.future : Future.value(<LocalSong>[]);
    });
    when(() => storage.syncSongs(any(), checkpoint: any(named: 'checkpoint')))
        .thenAnswer(
          (_) async =>
              const SongSyncResult(added: 0, updated: 0, removed: 0, total: 0),
        );

    final first = syncRepo.syncLibrary();
    final forced = syncRepo.syncLibrary(force: true);
    scan.complete(const []);
    await Future.wait([first, forced]);

    expect(calls, 2);
  });
}
