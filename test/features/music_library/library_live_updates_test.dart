import 'package:melodix/core/models/load_status.dart';

import 'dart:async';

import 'package:dartz/dartz.dart' show Either;
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/collections/song_collection.dart';
import 'package:melodix/core/database/music_local_storage.dart';
import 'package:melodix/core/database/song_library_update.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/models/local_song.dart';
import 'package:melodix/core/service/app_lifecycle_service.dart';
import 'package:melodix/features/music_library/data/mappers/song_mapper.dart';
import 'package:melodix/features/music_library/data/repositories/song_repository_impl.dart';
import 'package:melodix/core/entities/library_permission.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/entities/song_sort_order.dart';
import 'package:melodix/features/music_library/domain/usecases/build_library_catalog_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/check_library_permission_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_last_library_sync_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/open_library_settings_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/request_library_permission_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/sync_music_library_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_library_songs_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/library_collections_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/library_search_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_event.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fake_media_store.dart';
import '../../support/isar_test_db.dart';
import '../../support/legacy_library_grouping.dart';
import '../../support/sync_repository_factory.dart';

import 'package:melodix/features/music_library/domain/usecases/watch_library_sync_stage_usecase.dart';
import 'package:melodix/features/music_library/domain/entities/library_sync_stage.dart';

class _Check extends Mock implements CheckLibraryPermissionUseCase {}

class _Request extends Mock implements RequestLibraryPermissionUseCase {}

class _Sync extends Mock implements SyncMusicLibraryUseCase {}

class _LastSync extends Mock implements GetLastLibrarySyncUseCase {}

class _Settings extends Mock implements OpenLibrarySettingsUseCase {}

class _Lifecycle implements AppLifecycleService {
  @override
  Stream<void> get onResumed => const Stream.empty();
}

/// Real storage that counts full-library reads and can fail a write.
class _Storage extends MusicLocalStorageImpl {
  _Storage(super.isar);

  int fullReads = 0;
  bool failNextFavorite = false;

  /// When set, a full read waits for it after reading: the rows are then a
  /// snapshot older than writes committed meanwhile. [readTaken] completes
  /// once that snapshot exists.
  Completer<void>? holdReads;
  Completer<void> readTaken = Completer();

  @override
  Future<List<SongCollection>> getAllSongs() async {
    fullReads++;
    final rows = await super.getAllSongs();
    final hold = holdReads;
    if (hold != null) {
      if (!readTaken.isCompleted) readTaken.complete();
      await hold.future;
    }
    return rows;
  }

  @override
  Future<bool> toggleFavorite(int songId) {
    if (failNextFavorite) {
      failNextFavorite = false;
      throw StateError('disk full');
    }
    return super.toggleFavorite(songId);
  }
}

/// The real database, except that every write transaction fails after its
/// work ran (like a failed commit): Isar rolls all of it back.
class _CommitFailsIsar implements Isar {
  _CommitFailsIsar(this._real);

  final Isar _real;

  @override
  IsarCollection<T> collection<T>() => _real.collection<T>();

  @override
  Future<T> writeTxn<T>(Future<T> Function() callback, {bool silent = false}) =>
      _real.writeTxn(() async {
        await callback();
        throw StateError('commit failed');
      }, silent: silent);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// How the visible library reaches the bloc and what follows from it, on
/// real Isar: single-song edits patch the state in memory, real library
/// changes (sync) reload it, and albums / artists come from memory.
void main() {
  final skip = isarLibraryPath() == null ? 'No Isar library' : false;

  late Isar isar;
  late _Storage storage;
  late SongRepositoryImpl songs;
  late MusicLibraryBloc bloc;

  LocalSong local(
    int id, {
    String? title,
    String artist = 'Artist',
    String album = 'Album',
    int? albumId = 1,
  }) => LocalSong(
    id: id,
    title: title ?? 'Song ${id.toString().padLeft(3, '0')}',
    artist: artist,
    album: album,
    albumId: albumId,
    duration: Duration(seconds: 100 + id),
    path: '/music/$id.mp3',
    uri: 'content://media/external/audio/media/$id',
    size: 1000,
  );

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  setUp(() async {
    isar = await openTestIsar();
    storage = _Storage(isar);
    await storage.syncSongs([for (var i = 1; i <= 20; i++) local(i)]);
    songs = SongRepositoryImpl(
      storage: storage,
      musicService: FakeMediaStore(),
      mapper: const SongMapper(isAndroid: true),
    );
    final check = _Check();
    final lastSync = _LastSync();
    when(() => check()).thenAnswer((_) async => LibraryPermission.denied);
    when(() => lastSync()).thenAnswer((_) async => null);
    bloc = MusicLibraryBloc(
      checkPermission: check,
      requestPermission: _Request(),
      syncLibrary: _Sync(),
      getLastSync: lastSync,
      watchSongs: WatchLibrarySongsUseCase(songs),
      watchSyncStage: _NoStages(),
      lifecycle: _Lifecycle(),
      openSettings: _Settings(),
    )..add(const MusicLibraryStarted());
    await bloc.stream.firstWhere((s) => s.songs.length == 20);
    await settle();
    storage.fullReads = 0;
  });

  tearDown(() async {
    await bloc.close();
    await closeTestIsar(isar);
  });

  Song byId(int id) => bloc.state.songs.firstWhere((s) => s.id == id);

  /// Mapped songs straight from the database, for comparison.
  Future<List<Song>> fromDatabase() async => [
    for (final row
        in await isar.songCollections.where().sortByTitle().findAll())
      const SongMapper(isAndroid: true).toEntity(row),
  ];

  /// Indexes of songs whose instance changed between [before] and the state.
  List<int> replacedIds(List<Song> before) => [
    for (var i = 0; i < before.length; i++)
      if (!identical(before[i], bloc.state.songs[i])) before[i].id,
  ];

  group('1. play count', () {
    test('updates the song without a full reload', () async {
      final before = bloc.state.songs;

      // The call the player makes when a song starts.
      await storage.recordPlay(5);
      await settle();

      expect(byId(5).playCount, 1);
      expect(storage.fullReads, 0);
      expect(replacedIds(before), [5]);
      expect(bloc.state.songs, await fromDatabase());
    }, skip: skip);
  });

  group('2. favourite', () {
    test('toggling replaces only the affected song', () async {
      final before = bloc.state.songs;
      var emissions = 0;
      final sub = bloc.stream.listen((_) => emissions++);

      final result = await songs.toggleFavorite(7);
      await settle();
      await sub.cancel();

      expect(result.getOrElse(() => false), isTrue);
      expect(byId(7).isFavorite, isTrue);
      expect(replacedIds(before), [7]);
      expect(storage.fullReads, 0);
      expect(emissions, 1);
      expect(bloc.state.songs, await fromDatabase());
    }, skip: skip);

    test('bulk favourite replaces only the songs that changed', () async {
      await songs.toggleFavorite(3);
      await settle();
      final before = bloc.state.songs;
      var emissions = 0;
      final sub = bloc.stream.listen((_) => emissions++);

      await songs.setSongsFavorite([3, 4, 5], favorite: true);
      await settle();
      // Already favourites: no write, no update, no emission.
      await songs.setSongsFavorite([3, 4, 5], favorite: true);
      await settle();
      await sub.cancel();

      expect(replacedIds(before), [4, 5]);
      expect(emissions, 1);
      expect(storage.fullReads, 0);
      expect(bloc.state.songs, await fromDatabase());
    }, skip: skip);
  });

  group('3. removing songs', () {
    test('deleting songs removes them in memory', () async {
      final before = bloc.state.songs;

      await storage.removeSongs([4, 6]);
      await settle();

      expect(bloc.state.songs, hasLength(18));
      expect(storage.fullReads, 0);
      // Every other song is the same instance, in the same order.
      expect(
        bloc.state.songs.every((s) => before.any((b) => identical(b, s))),
        isTrue,
      );
      expect(bloc.state.songs, await fromDatabase());
    }, skip: skip);
  });

  group('4. database failures', () {
    test(
      'a failed favourite write leaves state and database as they were',
      () async {
        final before = bloc.state;
        var emissions = 0;
        final sub = bloc.stream.listen((_) => emissions++);
        storage.failNextFavorite = true;

        final Either<Failure, bool> result = await songs.toggleFavorite(2);
        await settle();
        await sub.cancel();

        expect(result.isLeft(), isTrue);
        expect(identical(bloc.state, before), isTrue);
        expect(emissions, 0);
        expect((await isar.songCollections.get(2))!.isFavorite, isFalse);
      },
      skip: skip,
    );

    test('a write that fails after running sends no update', () async {
      final failing = MusicLocalStorageImpl(_CommitFailsIsar(isar));
      final updates = <SongLibraryUpdate>[];
      final sub = failing.watchLibrary().listen(updates.add);
      await settle();

      await expectLater(failing.recordPlay(5), throwsStateError);
      await expectLater(failing.toggleFavorite(5), throwsStateError);
      await settle();
      await sub.cancel();

      expect(updates, hasLength(1)); // only the initial load
      expect(updates.single, isA<SongLibraryLoaded>());
      final row = (await isar.songCollections.get(5))!;
      expect((row.playCount, row.isFavorite), (0, false));
    }, skip: skip);

    test('a rolled-back play is never shown', () async {
      final before = bloc.state;

      // A real Isar error: a write transaction can't be nested, so this one
      // fails and nothing is committed.
      await expectLater(
        isar.writeTxn(() => storage.recordPlay(5)),
        throwsA(anything),
      );
      await settle();

      expect(identical(bloc.state, before), isTrue);
      expect((await isar.songCollections.get(5))!.playCount, 0);

      // The next real play still works.
      await storage.recordPlay(5);
      await settle();
      expect(byId(5).playCount, 1);
    }, skip: skip);
  });

  test('5. most played sorting follows play counts', () async {
    for (final (id, plays) in [(12, 3), (4, 1), (17, 2)]) {
      for (var i = 0; i < plays; i++) {
        await storage.recordPlay(id);
      }
    }
    await settle();

    final sorted = sortSongs(bloc.state.songs, SongSortOrder.mostPlayed);

    expect(sorted.take(3).map((s) => s.id), [12, 17, 4]);
    expect(sorted.take(3).map((s) => s.playCount), [3, 2, 1]);
    expect(storage.fullReads, 0);
  }, skip: skip);

  test('6. search stays correct after song updates', () async {
    final search = LibrarySearchCubit(debounce: Duration.zero)
      ..updateSources(songs: bloc.state.songs);
    final sub = bloc.stream.listen((s) => search.updateSources(songs: s.songs));
    search.queryChanged('Song 01'); // songs 010..019
    await settle();
    expect(search.state.results.songs, hasLength(10));

    await songs.toggleFavorite(11);
    await storage.removeSongs([12]);
    await settle();

    final found = search.state.results.songs;
    expect(found.map((s) => s.id), isNot(contains(12)));
    expect(found, hasLength(9));
    expect(found.firstWhere((s) => s.id == 11).isFavorite, isTrue);

    await sub.cancel();
    await search.close();
  }, skip: skip);

  group('7–8. albums and artists', () {
    test('7. built from the songs in memory, no database reads', () async {
      final cubit = LibraryCollectionsCubit(
        buildCatalog: const BuildLibraryCatalogUseCase(),
      );
      storage.fullReads = 0;

      await cubit.onLibraryChanged(bloc.state.songs);

      expect(cubit.state.status, LoadStatus.ready);
      expect(cubit.state.albums.single.songCount, 20);
      expect(storage.fullReads, 0);
      await cubit.close();
    }, skip: skip);

    test('8. identical to the previous implementation', () async {
      // Edge cases: missing album ids (grouped by name, case-insensitive),
      // artist names differing only in case, mixed-artist albums.
      await storage.syncSongs([
        local(1, album: 'Zeta', albumId: 10, artist: 'Ann'),
        local(2, album: 'Alpha', albumId: 20, artist: 'bob'),
        local(3, album: 'Zeta', albumId: 10, artist: 'Carl'),
        local(4, album: 'Live', albumId: null, artist: 'Bob'),
        local(5, album: 'live', albumId: null, artist: 'BOB'),
        local(6, album: 'alpha', albumId: 21, artist: 'Ann'),
        local(7, album: '', albumId: null, artist: 'Unknown artist'),
        for (var i = 8; i <= 60; i++)
          local(
            i,
            title: 'T${(i * 37) % 61}',
            album: 'Album ${i % 7}',
            albumId: i % 5 == 0 ? null : i % 7,
            artist: i.isEven ? 'Artist ${i % 4}' : 'artist ${i % 4}',
          ),
      ]);
      await settle();

      final rows = await storage.getAllSongs();
      final catalog = const BuildLibraryCatalogUseCase()(bloc.state.songs);
      final legacyAlbums = LegacyLibraryGrouping.albums(rows);
      final legacyArtists = LegacyLibraryGrouping.artists(rows);
      expect(catalog.albums, legacyAlbums);
      expect(catalog.artists, legacyArtists);
      expect(legacyAlbums.map((a) => a.artist), contains('Various artists'));
    }, skip: skip);
  });

  group('9. real library sync', () {
    test('reloads the library once and rebuilds albums', () async {
      final device = FakeMediaStore();
      for (var i = 1; i <= 20; i++) {
        device.add(title: 'Song ${i.toString().padLeft(3, '0')}');
      }
      final sync = buildSyncRepository(device: device, storage: storage);
      final collections = LibraryCollectionsCubit(
        buildCatalog: const BuildLibraryCatalogUseCase(),
      );
      final sub = bloc.stream.listen(
        (s) => collections.onLibraryChanged(s.songs),
      );
      await collections.onLibraryChanged(bloc.state.songs);
      final albumsBefore = collections.state.albums;
      storage.fullReads = 0;

      device
        ..add(title: 'Brand new', album: 'New album')
        ..add(title: 'Another new', album: 'New album');
      final result = await sync.syncLibrary(force: true);
      await settle();

      expect(result.isRight(), isTrue);
      expect(bloc.state.songs, await fromDatabase());
      expect(bloc.state.songs.map((s) => s.title), contains('Brand new'));
      // One reload for the sync (the full scan's own read is separate).
      expect(storage.fullReads, greaterThanOrEqualTo(1));
      expect(collections.state.albums, isNot(albumsBefore));
      expect(
        collections.state.albums.map((a) => a.title),
        contains('New album'),
      );

      // A sync that changes nothing sends no reload at all.
      storage.fullReads = 0;
      var emissions = 0;
      final count = bloc.stream.listen((_) => emissions++);
      await storage.syncSongs([
        for (final s in await isar.songCollections.where().findAll())
          LocalSong(
            id: s.id,
            title: s.title,
            artist: s.artist,
            album: s.album,
            albumId: s.albumId,
            duration: s.duration,
            path: s.path,
            uri: s.uri,
            size: s.sizeBytes,
            dateAdded: s.dateAdded,
          ),
      ]);
      await settle();
      expect(storage.fullReads, 0);
      expect(emissions, 0);

      await count.cancel();
      await sub.cancel();
      await collections.close();
    }, skip: skip);

    test('a slow reload never overwrites a newer play count', () async {
      final readsBefore = storage.fullReads;
      storage.holdReads = Completer();

      // A full reload; its read is held after the snapshot.
      storage.reloadLibrary();
      await storage.readTaken.future;
      // A play commits while that (now stale) reload is still in flight.
      await storage.recordPlay(5);
      storage.holdReads!.complete();
      await settle();

      expect(storage.fullReads, readsBefore + 1); // the reload arrived
      expect(byId(5).playCount, 1); // and the play still shows
      expect(bloc.state.songs, await fromDatabase());
    }, skip: skip);
  });
}

/// Never reports a stage (these tests don't look at progress).
class _NoStages implements WatchLibrarySyncStageUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Stream<LibrarySyncStage> call() => const Stream.empty();
}
