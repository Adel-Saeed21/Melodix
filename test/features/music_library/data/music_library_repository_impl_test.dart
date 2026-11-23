import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/core/database/collections/playlist_collection.dart';
import 'package:melodix/core/database/collections/song_collection.dart';
import 'package:melodix/core/database/music_local_storage.dart';
import 'package:melodix/core/database/playlist_local_storage.dart';
import 'package:melodix/core/errors/exceptions.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/models/local_song.dart';
import 'package:melodix/core/service/music_service.dart';
import 'package:melodix/core/service/permission_handling_service.dart';
import 'package:melodix/features/music_library/data/mappers/song_mapper.dart';
import 'package:melodix/features/music_library/data/repositories/music_library_repository_impl.dart';
import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/domain/entities/library_permission.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures.dart';

class MockMusicService extends Mock implements MusicService {}

class MockMusicLocalStorage extends Mock implements MusicLocalStorage {}

class MockPermissionService extends Mock implements PermissionHandlingService {}

class MockPlaylistStorage extends Mock implements PlaylistLocalStorage {}

void main() {
  late MockMusicService musicService;
  late MockMusicLocalStorage storage;
  late MockPermissionService permissions;
  late MockPlaylistStorage playlists;
  late MusicLibraryRepositoryImpl repository;
  final syncedAt = DateTime(2026, 11, 22, 10);

  setUp(() {
    musicService = MockMusicService();
    storage = MockMusicLocalStorage();
    permissions = MockPermissionService();
    repository = MusicLibraryRepositoryImpl(
      musicService: musicService,
      storage: storage,
      permissionService: permissions,
      playlistStorage: playlists = MockPlaylistStorage(),
      mapper: const SongMapper(isAndroid: true),
    );
    registerFallbackValue(<LocalSong>[]);
    registerFallbackValue(<int>[]);
    when(() => storage.getLastSyncedAt()).thenAnswer((_) async => syncedAt);
  });

  group('syncLibrary', () {
    test('scans, saves and reports what changed', () async {
      final scanned = [localSong(1), localSong(2)];
      when(() => musicService.getAllSongs()).thenAnswer((_) async => scanned);
      when(() => storage.syncSongs(scanned)).thenAnswer(
        (_) async =>
            const SongSyncResult(added: 1, updated: 1, removed: 3, total: 2),
      );

      final result = await repository.syncLibrary();

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

      final result = await repository.syncLibrary();

      final failure = result.swap().getOrElse(() => throw StateError('Left'));
      expect(failure, isA<PermissionFailure>());
      expect((failure as PermissionFailure).permanentlyDenied, isTrue);
      verifyNever(() => storage.syncSongs(any()));
    });

    test('maps other errors to LibraryFailure', () async {
      when(() => musicService.getAllSongs()).thenThrow(Exception('boom'));

      final result = await repository.syncLibrary();

      expect(result.isLeft(), isTrue);
      result.leftMap((f) => expect(f, isA<LibraryFailure>()));
    });

    test('concurrent calls share a single scan', () async {
      final scan = Completer<List<LocalSong>>();
      when(() => musicService.getAllSongs()).thenAnswer((_) => scan.future);
      when(() => storage.syncSongs(any())).thenAnswer(
        (_) async =>
            const SongSyncResult(added: 0, updated: 0, removed: 0, total: 0),
      );

      final first = repository.syncLibrary();
      final second = repository.syncLibrary();
      scan.complete(const []);
      await Future.wait([first, second]);

      verify(() => musicService.getAllSongs()).called(1);

      // A later call starts a new scan.
      await repository.syncLibrary();
      verify(() => musicService.getAllSongs()).called(1);
    });
  });

  test('checkPermission maps the platform status', () async {
    when(() => permissions.audioStatus())
        .thenAnswer((_) async => MediaPermissionStatus.permanentlyDenied);

    expect(
      await repository.checkPermission(),
      LibraryPermission.permanentlyDenied,
    );
  });

  test('watchSongs emits entities with content URIs', () async {
    when(() => storage.watchAllSongs())
        .thenAnswer((_) => Stream.value([songRow(4)]));

    final songs = await repository.watchSongs().first;

    expect(songs.single.id, 4);
    expect(
      songs.single.playbackUri.toString(),
      'content://media/external/audio/media/4',
    );
  });

  test('getAlbums groups saved songs', () async {
    when(
      () => storage.getAllSongs(),
    ).thenAnswer((_) async => [songRow(1, albumId: 5), songRow(2, albumId: 5)]);

    final albums = (await repository.getAlbums()).getOrElse(() => []);

    expect(albums.single.songCount, 2);
  });

  test('getAlbumSongs queries by album id and title', () async {
    const album = Album(
      albumId: 5,
      title: 'Album',
      artist: 'Artist',
      songCount: 1,
      duration: Duration.zero,
      artworkSongId: 1,
    );
    when(() => storage.getSongsByAlbum(albumId: 5, albumTitle: 'Album'))
        .thenAnswer((_) async => [songRow(1, albumId: 5)]);

    final songs = (await repository.getAlbumSongs(album)).getOrElse(() => []);

    expect(songs.single.id, 1);
  });

  test('read errors become LibraryFailure', () async {
    when(() => storage.getSongsByArtist('X')).thenThrow(Exception('db'));

    final result = await repository.getArtistSongs('X');

    result.fold(
      (f) => expect(f, isA<LibraryFailure>()),
      (_) => fail('expected failure'),
    );
  });

  group('song actions', () {
    test('toggleFavorite returns the new value', () async {
      when(() => storage.toggleFavorite(4)).thenAnswer((_) async => true);

      expect(
        (await repository.toggleFavorite(4)).getOrElse(() => false),
        isTrue,
      );
    });

    test('setSongHidden writes the flag', () async {
      when(() => storage.setHidden(4, hidden: true)).thenAnswer((_) async {});

      final result = await repository.setSongHidden(4, hidden: true);

      expect(result.isRight(), isTrue);
      verify(() => storage.setHidden(4, hidden: true)).called(1);
    });

    test('recordPlay counts a play', () async {
      when(() => storage.recordPlay(4)).thenAnswer((_) async {});

      expect((await repository.recordPlay(4)).isRight(), isTrue);
      verify(() => storage.recordPlay(4)).called(1);
    });

    test('bulk hide and favourite delegate to storage', () async {
      when(() => storage.setHiddenMany([1, 2], hidden: true))
          .thenAnswer((_) async {});
      when(() => storage.setFavoriteMany([1, 2], favorite: false))
          .thenAnswer((_) async {});

      expect(
        (await repository.setSongsHidden([1, 2], hidden: true)).isRight(),
        isTrue,
      );
      expect(
        (await repository.setSongsFavorite([1, 2], favorite: false)).isRight(),
        isTrue,
      );
    });

    test('deleteSongs removes only what the device deleted', () async {
      when(() => musicService.deleteSongs([1, 2, 3]))
          .thenAnswer((_) async => [1, 3]);
      when(() => storage.removeSongs([1, 3])).thenAnswer((_) async {});

      final result = await repository.deleteSongs([1, 2, 3]);

      expect(result.getOrElse(() => -1), 2);
      verify(() => storage.removeSongs([1, 3])).called(1);
    });

    test('deleteSongs declined by the user removes nothing', () async {
      when(() => musicService.deleteSongs(any())).thenAnswer((_) async => []);

      final result = await repository.deleteSongs([1]);

      expect(result.getOrElse(() => -1), 0);
      verifyNever(() => storage.removeSongs(any()));
    });

    test('write errors become LibraryFailure', () async {
      when(() => storage.toggleFavorite(4)).thenThrow(Exception('db'));

      final result = await repository.toggleFavorite(4);

      result.fold(
        (f) => expect(f, isA<LibraryFailure>()),
        (_) => fail('expected failure'),
      );
    });

    test('getAlbumForSong groups the album songs', () async {
      when(() => storage.getSongsByAlbum(albumId: 1, albumTitle: 'Album'))
          .thenAnswer((_) async => [songRow(1), songRow(2)]);
      final song = (await repository.watchSongsFor([songRow(1)])).single;

      final album = (await repository.getAlbumForSong(song))
          .getOrElse(() => null);

      expect(album?.songCount, 2);
    });

    test('addSongsToPlaylist returns how many were added', () async {
      when(() => playlists.addSongs(3, [1, 2])).thenAnswer((_) async => 1);

      final added = await repository.addSongsToPlaylist(3, [1, 2]);

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

      final result = await repository.watchPlaylists().first;

      expect(result.first.id, 4);
      expect(result.first.songCount, 2);
      expect(result.first.artworkSongId, 8);
      expect(result.last.artworkSongId, isNull);
    });

    test('getPlaylistSongs returns entities in order', () async {
      when(() => playlists.getPlaylistSongs(4))
          .thenAnswer((_) async => [songRow(9), songRow(8)]);

      final songs = (await repository.getPlaylistSongs(4)).getOrElse(() => []);

      expect(songs.map((s) => s.id), [9, 8]);
    });

    test('rename / delete / remove song delegate to storage', () async {
      when(() => playlists.renamePlaylist(4, 'New')).thenAnswer((_) async {});
      when(() => playlists.deletePlaylist(4)).thenAnswer((_) async {});
      when(() => playlists.removeSong(4, 8)).thenAnswer((_) async {});

      expect((await repository.renamePlaylist(4, 'New')).isRight(), isTrue);
      expect((await repository.deletePlaylist(4)).isRight(), isTrue);
      expect((await repository.removeSongFromPlaylist(4, 8)).isRight(), isTrue);
      verify(() => playlists.renamePlaylist(4, 'New')).called(1);
      verify(() => playlists.deletePlaylist(4)).called(1);
      verify(() => playlists.removeSong(4, 8)).called(1);
    });

    test('reorderPlaylistSongs saves the shown order', () async {
      when(() => playlists.reorderSongs(4, [3, 1, 2])).thenAnswer((_) async {});

      final result = await repository.reorderPlaylistSongs(4, [3, 1, 2]);

      expect(result.isRight(), isTrue);
      verify(() => playlists.reorderSongs(4, [3, 1, 2])).called(1);
    });

    test('togglePlaylistFavorite returns the new value', () async {
      when(() => playlists.toggleFavorite(4)).thenAnswer((_) async => true);

      final result = await repository.togglePlaylistFavorite(4);

      expect(result.getOrElse(() => false), isTrue);
    });
  });

  group('searchLibrary', () {
    test(
      'matches songs, artists, albums and playlists case-insensitively',
      () async {
        when(() => storage.getAllSongs()).thenAnswer(
          (_) async => [
            songRow(1, title: 'Nova Lights', artist: 'Aria', album: 'Dawn'),
            songRow(
              2,
              title: 'Rain',
              artist: 'Nova',
              album: 'Clouds',
              albumId: 2,
            ),
            songRow(
              3,
              title: 'Sun',
              artist: 'Aria',
              album: 'Supernova',
              albumId: 3,
            ),
            songRow(
              4,
              title: 'Other',
              artist: 'Zed',
              album: 'Misc',
              albumId: 4,
            ),
          ],
        );
        when(() => playlists.getAllPlaylists()).thenAnswer(
          (_) async => [
            PlaylistCollection.create('nova nights')..id = 7,
            PlaylistCollection.create('Gym')..id = 8,
          ],
        );

        final results = (await repository.searchLibrary(' NOVA '))
            .getOrElse(() => throw StateError('expected results'));

        expect(results.songs.map((s) => s.id), [1, 2, 3]);
        expect(results.artists.map((a) => a.name), ['Nova']);
        expect(results.albums.map((a) => a.title), ['Clouds', 'Supernova']);
        expect(results.playlists.map((p) => p.name), ['nova nights']);
      },
    );

    test('an empty query returns empty results without reading', () async {
      final results = (await repository.searchLibrary('   '))
          .getOrElse(() => throw StateError('expected results'));

      expect(results.isEmpty, isTrue);
      verifyNever(() => storage.getAllSongs());
    });
  });
}

extension on MusicLibraryRepositoryImpl {
  /// Maps rows the same way the repository does, via its public stream.
  Future<List<Song>> watchSongsFor(List<SongCollection> rows) async => rows
      .map(const SongMapper(isAndroid: true).toEntity)
      .toList(growable: false);
}
