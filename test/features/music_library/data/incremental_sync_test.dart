import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/collections/playlist_collection.dart';
import 'package:melodix/core/database/collections/song_collection.dart';
import 'package:melodix/features/music_library/data/datasources/music_local_storage.dart';
import 'package:melodix/features/music_library/data/models/local_song.dart';
import 'package:melodix/core/utils/debug_counters.dart';
import 'package:melodix/features/music_library/data/repositories/library_sync_repository_impl.dart';
import 'package:melodix/features/music_library/domain/entities/library_sync_result.dart';

import '../../../support/fake_media_store.dart';
import '../../../support/sync_repository_factory.dart';
import '../../../support/isar_test_db.dart';

import 'package:melodix/features/music_library/domain/entities/library_sync_stage.dart';

/// Real storage that can be told to fail the next incremental save.
class FlakyStorage extends MusicLocalStorageImpl {
  FlakyStorage(super.isar);

  bool failNextApply = false;

  @override
  Future<SongSyncResult> applyChanges({
    required List<LocalSong> upserts,
    required Iterable<int> deletedIds,
    required String checkpoint,
  }) {
    if (failNextApply) {
      failNextApply = false;
      throw StateError('disk full');
    }
    return super.applyChanges(
      upserts: upserts,
      deletedIds: deletedIds,
      checkpoint: checkpoint,
    );
  }
}

void main() {
  final skip = isarLibraryPath() == null ? 'No Isar library' : false;

  late Isar isar;
  late FlakyStorage storage;
  late FakeMediaStore device;
  late LibrarySyncRepositoryImpl repository;

  setUp(() async {
    isar = await openTestIsar();
    storage = FlakyStorage(isar);
    device = FakeMediaStore(volumes: ['external_primary', 'sd_card']);
    repository = buildSyncRepository(device: device, storage: storage);
  });

  tearDown(() => closeTestIsar(isar));

  Future<LibrarySyncResult> sync({bool force = false}) async =>
      (await repository.syncLibrary(force: force))
          .getOrElse(() => throw StateError('sync failed'));

  Future<SongCollection?> saved(int id) => isar.songCollections.get(id);
  Future<Set<int>> savedIds() => storage.getAllSongIds();

  /// Library with a first full scan already done.
  Future<Map<String, int>> seeded() async {
    final ids = {
      'a': device.add(title: 'Alpha'),
      'b': device.add(title: 'Bravo'),
      'c': device.add(title: 'Charlie', volume: 'sd_card'),
    };
    final first = await sync();
    expect(first.incremental, isFalse); // first sync: full
    expect(device.fullScans, 1);
    DebugCounters.reset();
    return ids;
  }

  group('progress stages', () {
    /// The stages [action]'s sync reports, in order.
    Future<List<LibrarySyncStage>> stagesOf(
      Future<void> Function() action,
    ) async {
      final stages = <LibrarySyncStage>[];
      final sub = repository.watchSyncStage().listen(stages.add);
      await action();
      await pumpEventQueue();
      await sub.cancel();
      return stages;
    }

    test('a first (full) scan checks, reads, then saves', () async {
      device.add(title: 'Alpha');
      expect(await stagesOf(sync), [
        LibrarySyncStage.checking,
        LibrarySyncStage.reading,
        LibrarySyncStage.saving,
      ]);
    }, skip: skip);

    test('a scan of only the changes checks, reads, then saves', () async {
      await seeded();
      device.add(title: 'Delta');
      expect(await stagesOf(sync), [
        LibrarySyncStage.checking,
        LibrarySyncStage.reading,
        LibrarySyncStage.saving,
      ]);
    }, skip: skip);

    test('nothing changed: it stops after checking', () async {
      await seeded();
      expect(await stagesOf(sync), [LibrarySyncStage.checking]);
    }, skip: skip);

    test('a failed save never reports more than it reached', () async {
      await seeded();
      device.add(title: 'Delta');
      storage.failNextApply = true;
      final stages = await stagesOf(() => repository.syncLibrary());
      expect(stages, [
        LibrarySyncStage.checking,
        LibrarySyncStage.reading,
        LibrarySyncStage.saving,
      ]);
    }, skip: skip);
  });

  group('incremental sync', () {
    test('nothing changed: no scan at all', () async {
      await seeded();
      final result = await sync();

      expect(result.skipped, isTrue);
      expect(device.fullScans, 1);
      expect(device.deltaQueries, 0);
    }, skip: skip);

    test('an added file is picked up without a full scan', () async {
      await seeded();
      final id = device.add(title: 'Delta');

      final result = await sync();

      expect(result.incremental, isTrue);
      expect(result.added, 1);
      expect((await saved(id))!.title, 'Delta');
      expect(device.fullScans, 1); // still only the first one
      expect(DebugCounters.of('mediaStoreDelta'), 1);
    }, skip: skip);

    test('a modified file (tag edit) is updated', () async {
      final ids = await seeded();
      device.modify(ids['a']!, title: 'Alpha (Remastered)');

      final result = await sync();

      expect(result.updated, 1);
      expect((await saved(ids['a']!))!.title, 'Alpha (Remastered)');
    }, skip: skip);

    test('a renamed file keeps its favourite and play count', () async {
      final ids = await seeded();
      await storage.toggleFavorite(ids['b']!);
      await storage.recordPlay(ids['b']!);
      device.rename(ids['b']!, '/storage/external_primary/Music/Bravo 2.mp3');

      await sync();

      final row = (await saved(ids['b']!))!;
      expect(row.path, '/storage/external_primary/Music/Bravo 2.mp3');
      expect(row.isFavorite, isTrue);
      expect(row.playCount, 1);
    }, skip: skip);

    test('a file moved to another folder is updated', () async {
      final ids = await seeded();
      device.move(ids['a']!, newPath: '/storage/external_primary/Albums/A.mp3');

      await sync();

      expect(
        (await saved(ids['a']!))!.path,
        '/storage/external_primary/Albums/A.mp3',
      );
    }, skip: skip);

    test(
      'a file moved into Recordings is removed (filter rules kept)',
      () async {
        final ids = await seeded();
        device.move(
          ids['a']!,
          newPath: '/storage/external_primary/Recordings/A.mp3',
        );

        final result = await sync();

        expect(result.removed, 1);
        expect(await saved(ids['a']!), isNull);
      },
      skip: skip,
    );

    test('a file moved to another volume is updated', () async {
      final ids = await seeded();
      device.move(
        ids['a']!,
        newPath: '/storage/sd_card/Music/Alpha.mp3',
        toVolume: 'sd_card',
      );

      await sync();

      expect(
        (await saved(ids['a']!))!.path,
        '/storage/sd_card/Music/Alpha.mp3',
      );
    }, skip: skip);

    test('a deleted file is removed (found by ids, not generations)', () async {
      final ids = await seeded();
      await isar.writeTxn(
        () => isar.playlistCollections.put(
          PlaylistCollection.create('Mix')..songIds = [ids['a']!, ids['b']!],
        ),
      );
      device.delete(ids['a']!);

      final result = await sync();

      expect(result.incremental, isTrue);
      expect(result.removed, 1);
      expect(await savedIds(), {ids['b'], ids['c']});
      final playlist = await isar.playlistCollections.where().findFirst();
      expect(playlist!.songIds, [ids['b']]);
    }, skip: skip);
  });

  group('volumes', () {
    test('each volume keeps its own generation', () async {
      final ids = await seeded();
      // Many changes on the phone, one on the SD card.
      for (var i = 0; i < 5; i++) {
        device.modify(ids['a']!, title: 'Alpha $i');
      }
      device.modify(ids['c']!, title: 'Charlie 2');

      await sync();

      expect((await saved(ids['a']!))!.title, 'Alpha 4');
      expect((await saved(ids['c']!))!.title, 'Charlie 2');
      // Next change on the SD card only reads the SD card's new rows.
      device.rowsTransferred = 0;
      device.modify(ids['c']!, title: 'Charlie 3');
      await sync();
      expect(device.rowsTransferred, 1);
    }, skip: skip);

    test('an inserted volume is read entirely', () async {
      await seeded();
      device.insertVolume('usb');
      final usb = device.add(title: 'From USB', volume: 'usb');

      final result = await sync();

      expect(result.incremental, isTrue);
      expect((await saved(usb))!.title, 'From USB');
    }, skip: skip);

    test('a removed volume removes its songs', () async {
      final ids = await seeded();
      device.removeVolume('sd_card');

      final result = await sync();

      expect(result.incremental, isTrue);
      expect(await saved(ids['c']!), isNull);
      expect(await savedIds(), {ids['a'], ids['b']});
    }, skip: skip);
  });

  group('fallbacks to a full scan', () {
    test('MediaStore rebuilt (new version)', () async {
      await seeded();
      device.rebuildDatabase();

      final result = await sync();

      expect(result.incremental, isFalse);
      expect(device.fullScans, 2);
      // The new checkpoint makes the next sync incremental again.
      device.add(title: 'After rebuild');
      expect((await sync()).incremental, isTrue);
    }, skip: skip);

    test('no generations (Android 10 / iOS)', () async {
      device.supportsGenerations = false;
      device.add(title: 'Alpha');
      await sync();
      await sync();

      expect(device.fullScans, 2);
      expect(device.deltaQueries, 0);
      expect(await storage.getSyncCheckpoint(), isNull);
    }, skip: skip);

    test('pull-to-refresh is always a full scan', () async {
      await seeded();
      await sync(force: true);

      expect(device.fullScans, 2);
      expect(device.deltaQueries, 0);
    }, skip: skip);

    test('a failed change query fails safely, then retries', () async {
      await seeded();
      final checkpointBefore = await storage.getSyncCheckpoint();
      final id = device.add(title: 'Delta');
      device.failNextChanges = true;

      final failed = await repository.syncLibrary();

      // No silent full-scan fallback, nothing saved, checkpoint kept.
      expect(failed.isLeft(), isTrue);
      expect(device.fullScans, 1);
      expect(await saved(id), isNull);
      expect(await storage.getSyncCheckpoint(), checkpointBefore);

      final retry = await sync();
      expect(retry.incremental, isTrue);
      expect((await saved(id))!.title, 'Delta');
    }, skip: skip);
  });

  group('failures and recovery', () {
    test('a failed save keeps the old checkpoint and loses nothing', () async {
      final ids = await seeded();
      final checkpointBefore = await storage.getSyncCheckpoint();
      final added = device.add(title: 'Delta');
      device.delete(ids['a']!);
      storage.failNextApply = true;

      final failed = await repository.syncLibrary();

      expect(failed.isLeft(), isTrue);
      expect(await storage.getSyncCheckpoint(), checkpointBefore);
      expect(await saved(added), isNull); // nothing half-applied

      // Next sync retries the same changes from the old checkpoint.
      final retry = await sync();
      expect(retry.incremental, isTrue);
      expect((await saved(added))!.title, 'Delta');
      expect(await saved(ids['a']!), isNull);
      expect(device.fullScans, 1);
    }, skip: skip);

    test('a failed full scan keeps the old checkpoint', () async {
      await seeded();
      final checkpointBefore = await storage.getSyncCheckpoint();
      device.failNextFullScan = true;

      final failed = await repository.syncLibrary(force: true);

      expect(failed.isLeft(), isTrue);
      expect(await storage.getSyncCheckpoint(), checkpointBefore);
    }, skip: skip);

    test('a change during the sync is picked up next time', () async {
      final ids = await seeded();
      device.modify(ids['a']!, title: 'Alpha 2');
      // The checkpoint is read before the rows; a change landing after it
      // gets a later generation.
      final checkpoint = await device.currentCheckpoint();
      device.modify(ids['b']!, title: 'Bravo 2');
      expect(
        checkpoint!.generations['external_primary'],
        lessThan(
          (await device.currentCheckpoint())!.generations['external_primary']!,
        ),
      );

      await sync();
      await sync();

      expect((await saved(ids['a']!))!.title, 'Alpha 2');
      expect((await saved(ids['b']!))!.title, 'Bravo 2');
    }, skip: skip);
  });

  test('incremental and full scans produce the same library', () async {
    final ids = await seeded();
    device.modify(ids['a']!, title: 'Alpha 2');
    device.rename(ids['b']!, '/storage/external_primary/Music/B.mp3');
    device.delete(ids['c']!);
    device.add(title: 'Delta', volume: 'sd_card');
    await sync(); // incremental

    Future<List<String>> snapshot() async => [
      for (final s in await isar.songCollections.where().findAll())
        '${s.id}|${s.title}|${s.artist}|${s.album}|${s.path}|${s.uri}|${s.durationMs}|${s.sizeBytes}|${s.dateAdded}',
    ];
    final afterIncremental = await snapshot();

    await sync(force: true); // full, same device
    expect(await snapshot(), afterIncremental);
  }, skip: skip);
}
