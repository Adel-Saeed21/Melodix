import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/collections/playlist_collection.dart';
import 'package:melodix/core/database/collections/recent_music_collection.dart';
import 'package:melodix/core/database/collections/song_collection.dart';
import 'package:melodix/core/database/music_local_storage.dart';
import 'package:melodix/core/models/local_song.dart';

import '../../support/isar_test_db.dart';

LocalSong song(int id, {String? title, String? path}) => LocalSong(
  id: id,
  title: title ?? 'Song $id',
  artist: 'Artist',
  album: 'Album',
  albumId: 1,
  duration: const Duration(minutes: 3),
  path: path ?? '/music/$id.mp3',
  uri: 'content://media/external/audio/media/$id',
  size: 1000,
);

/// An id list that fails part-way through being read (to abort a
/// transaction after some writes already happened).
class _FailingIds extends Iterable<int> {
  @override
  Iterator<int> get iterator => throw StateError('boom');
}

void main() {
  late Isar isar;
  late MusicLocalStorage storage;

  setUp(() async {
    isar = await openTestIsar();
    storage = MusicLocalStorageImpl(isar);
  });

  tearDown(() => closeTestIsar(isar));

  final skip = isarLibraryPath() == null ? 'No Isar library' : false;

  group('applyChanges', () {
    test('adds new songs and saves the checkpoint', () async {
      final result = await storage.applyChanges(
        upserts: [song(1), song(2)],
        deletedIds: const [],
        checkpoint: 'cp-1',
      );

      expect(result.added, 2);
      expect(result.total, 2);
      expect(await storage.getAllSongIds(), {1, 2});
      expect(await storage.getSyncCheckpoint(), 'cp-1');
      expect(await storage.getLastSyncedAt(), isNotNull);
    }, skip: skip);

    test('rewrites only songs whose file data changed', () async {
      await storage.applyChanges(
        upserts: [song(1), song(2)],
        deletedIds: const [],
        checkpoint: 'cp-1',
      );

      final result = await storage.applyChanges(
        upserts: [
          song(1),
          song(2, title: 'Renamed tag'),
        ],
        deletedIds: const [],
        checkpoint: 'cp-2',
      );

      expect(result.added, 0);
      expect(result.updated, 1);
      expect((await isar.songCollections.get(2))!.title, 'Renamed tag');
    }, skip: skip);

    test(
      'keeps favourite, play count, hidden state and first-seen date',
      () async {
        await storage.applyChanges(
          upserts: [song(1)],
          deletedIds: const [],
          checkpoint: 'cp-1',
        );
        final addedAt = (await isar.songCollections.get(1))!.addedAt;
        await storage.toggleFavorite(1);
        await storage.recordPlay(1);
        await storage.setHidden(1, hidden: true);

        await storage.applyChanges(
          upserts: [song(1, path: '/moved/1.mp3')], // renamed / moved
          deletedIds: const [],
          checkpoint: 'cp-2',
        );

        final row = (await isar.songCollections.get(1))!;
        expect(row.path, '/moved/1.mp3');
        expect(row.isFavorite, isTrue);
        expect(row.playCount, 1);
        expect(row.isHidden, isTrue);
        expect(row.addedAt, addedAt);
      },
      skip: skip,
    );

    test('deletes songs everywhere: library, recents and playlists', () async {
      await storage.applyChanges(
        upserts: [song(1), song(2)],
        deletedIds: const [],
        checkpoint: 'cp-1',
      );
      await storage.recordPlay(1);
      await isar.writeTxn(
        () => isar.playlistCollections.put(
          PlaylistCollection.create('Mix')..songIds = [1, 2],
        ),
      );

      final result = await storage.applyChanges(
        upserts: const [],
        deletedIds: [1, 999], // 999 was never saved
        checkpoint: 'cp-2',
      );

      expect(result.removed, 1);
      expect(await storage.getAllSongIds(), {2});
      expect(await isar.recentMusicCollections.get(1), isNull);
      expect((await isar.playlistCollections.where().findFirst())!.songIds, [
        2,
      ]);
    }, skip: skip);

    test('a song both upserted and listed as deleted is kept', () async {
      final result = await storage.applyChanges(
        upserts: [song(1)],
        deletedIds: [1],
        checkpoint: 'cp-1',
      );

      expect(result.removed, 0);
      expect(await storage.getAllSongIds(), {1});
    }, skip: skip);

    test('a failure saves nothing: no songs and no new checkpoint', () async {
      await storage.applyChanges(
        upserts: [song(1)],
        deletedIds: const [],
        checkpoint: 'cp-1',
      );

      await expectLater(
        storage.applyChanges(
          upserts: [
            song(1, title: 'Changed'),
            song(2),
          ],
          deletedIds: _FailingIds(),
          checkpoint: 'cp-2',
        ),
        throwsStateError,
      );

      expect(await storage.getAllSongIds(), {1});
      expect((await isar.songCollections.get(1))!.title, 'Song 1');
      expect(await storage.getSyncCheckpoint(), 'cp-1');
    }, skip: skip);
  });

  test('watchFavorite follows the song\'s favourite flag', () async {
    await storage.applyChanges(
      upserts: [song(1), song(2)],
      deletedIds: const [],
      checkpoint: 'cp',
    );
    final seen = <bool>[];
    final sub = storage.watchFavorite(1).listen(seen.add);
    await pumpEventQueue();

    await storage.toggleFavorite(1);
    await pumpEventQueue();
    await storage.toggleFavorite(2); // another song: no event
    await pumpEventQueue();
    await storage.setFavoriteMany([1], favorite: false);
    await pumpEventQueue();

    expect(seen, [false, true, false]);
    await sub.cancel();
  }, skip: skip);

  test('watchFavorite reports false for a song that is gone', () async {
    expect(await storage.watchFavorite(404).first, isFalse);
  }, skip: skip);

  test('getAllSongIds includes hidden songs', () async {
    await storage.applyChanges(
      upserts: [song(1), song(2)],
      deletedIds: const [],
      checkpoint: 'cp',
    );
    await storage.setHidden(2, hidden: true);

    expect(await storage.getAllSongIds(), {1, 2});
    expect(await storage.countSongs(), 1); // visible only
  }, skip: skip);

  test('a full sync saves its checkpoint too', () async {
    await storage.syncSongs([song(1)], checkpoint: 'full-cp');

    expect(await storage.getSyncCheckpoint(), 'full-cp');

    await storage.syncSongs([song(1)]); // e.g. Android 10: no checkpoint
    expect(await storage.getSyncCheckpoint(), isNull);
  }, skip: skip);
}
