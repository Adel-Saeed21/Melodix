import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/collections/playlist_collection.dart';
import 'package:melodix/core/database/collections/recent_music_collection.dart';
import 'package:melodix/core/database/collections/song_collection.dart';
import 'package:melodix/core/database/collections/song_history_collection.dart';
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

    test('keeps favourite, play count and first-seen date', () async {
      await storage.applyChanges(
        upserts: [song(1)],
        deletedIds: const [],
        checkpoint: 'cp-1',
      );
      final addedAt = (await isar.songCollections.get(1))!.addedAt;
      await storage.toggleFavorite(1);
      await storage.recordPlay(1);

      await storage.applyChanges(
        upserts: [song(1, path: '/moved/1.mp3')], // renamed / moved
        deletedIds: const [],
        checkpoint: 'cp-2',
      );

      final row = (await isar.songCollections.get(1))!;
      expect(row.path, '/moved/1.mp3');
      expect(row.isFavorite, isTrue);
      expect(row.playCount, 1);
      expect(row.addedAt, addedAt);
    }, skip: skip);

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

  test('a full sync saves its checkpoint too', () async {
    await storage.syncSongs([song(1)], checkpoint: 'full-cp');

    expect(await storage.getSyncCheckpoint(), 'full-cp');

    await storage.syncSongs([song(1)]); // e.g. Android 10: no checkpoint
    expect(await storage.getSyncCheckpoint(), isNull);
  }, skip: skip);

  group('listening history', () {
    Future<SongCollection> row(int id) async =>
        (await isar.songCollections.get(id))!;

    /// A row as saved by a version from before listening time was kept.
    Future<void> legacy(int id, {required int plays}) async {
      await storage.applyChanges(
        upserts: [song(id)],
        deletedIds: const [],
        checkpoint: 'cp',
      );
      final r = await row(id);
      await isar.writeTxn(
        () => isar.songCollections.put(
          r
            ..playCount = plays
            ..listenedMs = null,
        ),
      );
    }

    test('listening adds up, without touching the play count', () async {
      await storage.applyChanges(
        upserts: [song(1)],
        deletedIds: const [],
        checkpoint: 'cp',
      );
      await storage.addListening(1, const Duration(seconds: 25));
      await storage.addListening(1, const Duration(seconds: 10));

      final r = await row(1);
      expect(r.listenedMs, 35000);
      expect(r.playCount, 0);
    }, skip: skip);

    test(
      'old rows: their estimate (plays × length) is kept, then added to',
      () async {
        await legacy(1, plays: 4); // 4 × 3 min = 12 min, estimated
        expect((await row(1)).listenedOrEstimateMs, 12 * 60000);

        await storage.addListening(1, const Duration(seconds: 30));
        expect((await row(1)).listenedMs, 12 * 60000 + 30000);
      },
      skip: skip,
    );

    test(
      'old rows: the estimate is fixed before a new play, not after',
      () async {
        await legacy(1, plays: 2);
        await storage.recordPlay(1); // a new play: 3 plays now
        await storage.addListening(1, const Duration(seconds: 40));

        final r = await row(1);
        expect(r.playCount, 3);
        // 2 old plays estimated (6 min) + the 40 s really heard: the new
        // play isn't also counted as a full song.
        expect(r.listenedMs, 6 * 60000 + 40000);
      },
      skip: skip,
    );

    test('a re-scan keeps the time listened', () async {
      await storage.applyChanges(
        upserts: [song(1)],
        deletedIds: const [],
        checkpoint: 'cp-1',
      );
      await storage.addListening(1, const Duration(seconds: 50));
      await storage.syncSongs([song(1, title: 'Renamed')]);

      final r = await row(1);
      expect(r.title, 'Renamed');
      expect(r.listenedMs, 50000);
    }, skip: skip);

    test(
      'a removed song keeps its history; never-played ones leave none',
      () async {
        await storage.applyChanges(
          upserts: [song(1), song(2)],
          deletedIds: const [],
          checkpoint: 'cp',
        );
        await storage.recordPlay(1);
        await storage.addListening(1, const Duration(seconds: 45));
        await storage.removeSongs([1, 2]);

        expect(await isar.songCollections.count(), 0);
        final kept = await isar.songHistoryCollections.where().findAll();
        expect(kept.map((h) => h.id), [1]);
        expect(kept.single.playCount, 1);
        expect(kept.single.listenedMs, 45000);
        expect(kept.single.title, 'Song 1');
      },
      skip: skip,
    );

    test('a song deleted by a sync keeps its history too', () async {
      await storage.syncSongs([song(1), song(2)]);
      await storage.recordPlay(2);
      await storage.syncSongs([song(1)]); // song 2's file is gone

      final kept = await isar.songHistoryCollections.get(2);
      expect(kept?.playCount, 1);
    }, skip: skip);

    test('a song that comes back gets its history back', () async {
      await storage.applyChanges(
        upserts: [song(1)],
        deletedIds: const [],
        checkpoint: 'cp-1',
      );
      await storage.recordPlay(1);
      await storage.addListening(1, const Duration(seconds: 40));
      await storage.toggleFavorite(1);
      // The SD card is taken out…
      await storage.applyChanges(
        upserts: const [],
        deletedIds: [1],
        checkpoint: 'cp-2',
      );
      // …and put back.
      await storage.applyChanges(
        upserts: [song(1)],
        deletedIds: const [],
        checkpoint: 'cp-3',
      );

      final r = await row(1);
      expect(r.playCount, 1);
      expect(r.listenedMs, 40000);
      expect(r.isFavorite, isTrue);
      expect(await isar.songHistoryCollections.count(), 0);
    }, skip: skip);

    test('a history row from an old version is merged too', () async {
      await isar.writeTxn(
        () => isar.songHistoryCollections.put(
          SongHistoryCollection()
            ..id = 9
            ..title = 'Back'
            ..artist = 'A'
            ..durationMs = 180000
            ..playCount = 2
            ..listenedMs = 360000
            ..removedAt = DateTime(2026),
        ),
      );
      await storage.syncSongs([song(9)]);

      final r = await row(9);
      expect((r.playCount, r.listenedMs), (2, 360000));
    }, skip: skip);
  });
}
