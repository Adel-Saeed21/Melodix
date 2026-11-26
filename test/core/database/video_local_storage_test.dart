import 'dart:async';

import 'package:melodix/core/database/collections/library_metadata_collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/collections/video_collection.dart';
import 'package:melodix/core/database/video_local_storage.dart';
import 'package:melodix/core/errors/exceptions.dart';
import 'package:melodix/core/models/local_video.dart';

import '../../support/isar_test_db.dart';

LocalVideo video(String id, {String? title, int seconds = 60, int day = 1}) =>
    LocalVideo(
      id: id,
      title: title ?? 'Video $id',
      duration: Duration(seconds: seconds),
      width: 1920,
      height: 1080,
      createdAt: DateTime(2026, 1, day),
    );

void main() {
  final skip = isarLibraryPath() == null ? 'No Isar library' : false;
  late Isar isar;
  late VideoLocalStorage storage;

  setUp(() async {
    if (skip != false) return;
    isar = await openTestIsar();
    storage = VideoLocalStorageImpl(isar);
  });

  tearDown(() async {
    if (skip == false) await closeTestIsar(isar);
  });

  group('sync', skip: skip, () {
    test('adds, updates and removes; counts each', () async {
      await storage.syncVideos([video('a'), video('b'), video('c')]);
      final result = await storage.syncVideos([
        video('a'),
        video('b', title: 'Renamed'),
        video('d'),
      ]);

      expect(result.added, 1);
      expect(result.updated, 1);
      expect(result.removed, 1);
      expect(result.total, 3);
      final all = await storage.getAllVideos();
      expect(all.map((v) => v.videoId), unorderedEquals(['a', 'b', 'd']));
      expect(all.firstWhere((v) => v.videoId == 'b').title, 'Renamed');
    });

    test('an unchanged re-scan writes nothing (no watcher wake-up)', () async {
      await storage.syncVideos([video('a'), video('b')]);
      var changes = 0;
      final sub = isar.videoCollections.watchLazy().listen((_) => changes++);
      final result = await storage.syncVideos([video('a'), video('b')]);
      await pumpEventQueue();
      await sub.cancel();

      expect(result.hasChanges, isFalse);
      expect(changes, 0);
    });

    test('an empty scan never wipes the library unless confirmed', () async {
      await storage.syncVideos([video('a'), video('b')]);

      await expectLater(
        storage.syncVideos(const []),
        throwsA(isA<MediaQueryException>()),
      );
      expect(await storage.getAllVideos(), hasLength(2));

      // The device itself counted 0: the videos really are gone.
      final result = await storage.syncVideos(const [], confirmedEmpty: true);
      expect(result.removed, 2);
      expect(await storage.getAllVideos(), isEmpty);
    });

    test('keeps favourites, plays and resume points across scans', () async {
      await storage.syncVideos([video('a', seconds: 600)]);
      await storage.toggleFavorite('a');
      await storage.recordPlay('a');
      await storage.savePlaybackPosition('a', const Duration(minutes: 3));

      // Its details changed on the device: the row is rewritten.
      await storage.syncVideos([video('a', title: 'New', seconds: 600)]);

      final a = (await storage.getAllVideos()).single;
      expect(a.title, 'New');
      expect(a.isFavorite, isTrue);
      final progress = (await storage.getProgress('a'))!;
      expect(progress.playCount, 1);
      expect(progress.position, const Duration(minutes: 3));
    });

    test('a removed video takes its progress with it', () async {
      await storage.syncVideos([video('a'), video('b')]);
      await storage.savePlaybackPosition('a', const Duration(minutes: 1));

      await storage.syncVideos([video('b')]);
      expect(await storage.getProgress('a'), isNull);
    });
  });

  test('favourites are watched live, newest first', skip: skip, () async {
    await storage.syncVideos([video('a', day: 1), video('b', day: 2)]);
    final emitted = StreamController<List<String>>();
    final sub = storage.watchFavoriteVideos().listen(
      (videos) => emitted.add([for (final v in videos) v.videoId]),
    );
    // Each change is awaited as it arrives: Isar reports from its own
    // thread, so a fixed number of event-loop turns can be too few on a
    // busy machine.
    final updates = StreamIterator(emitted.stream);
    Future<List<String>> next() async {
      expect(
        await updates.moveNext().timeout(const Duration(seconds: 5)),
        isTrue,
      );
      return updates.current;
    }

    expect(await next(), <String>[]);
    await storage.toggleFavorite('a');
    expect(await next(), ['a']);
    await storage.toggleFavorite('b');
    expect(await next(), ['b', 'a']);
    await storage.toggleFavorite('a');
    expect(await next(), ['b']);

    await sub.cancel();
    await updates.cancel();
    await emitted.close();
  });

  group('progress', skip: skip, () {
    test('saving progress never wakes the library watchers', () async {
      await storage.syncVideos([video('a', seconds: 600)]);
      var libraryChanges = 0;
      final library = storage
          .watchAllVideos()
          .skip(1)
          .listen((_) => libraryChanges++);
      final favourites = storage
          .watchFavoriteVideos()
          .skip(1)
          .listen((_) => libraryChanges++);
      // Isar reports changes from its own thread: wait for the real update
      // (not a fixed number of event-loop turns, which a busy machine can
      // outrun).
      final saved = storage.watchProgress().firstWhere(
        (rows) => rows.any(
          (r) => r.position == const Duration(minutes: 3) && r.playCount == 1,
        ),
      );

      for (var minute = 1; minute <= 3; minute++) {
        await storage.savePlaybackPosition('a', Duration(minutes: minute));
      }
      await storage.recordPlay('a');
      await saved.timeout(const Duration(seconds: 5));
      // A library emission would have arrived by now (same writes, same
      // thread, earlier).
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await library.cancel();
      await favourites.cancel();

      expect(libraryChanges, 0);
    });

    test(
      'a video never played has none; one not in the library gets none',
      () async {
        await storage.syncVideos([video('a')]);
        expect(await storage.getProgress('a'), isNull);

        await storage.savePlaybackPosition('gone', const Duration(minutes: 1));
        await storage.recordPlay('gone');
        expect(await storage.getProgress('gone'), isNull);
      },
    );

    test('plays count up and stamp the time', () async {
      await storage.syncVideos([video('a')]);
      await storage.recordPlay('a');
      await storage.recordPlay('a');
      final row = (await storage.getProgress('a'))!;
      expect(row.playCount, 2);
      expect(row.lastPlayedAt, isNotNull);
    });
  });

  group('bulk', skip: skip, () {
    test('favourite several at once (unknown ids ignored)', () async {
      await storage.syncVideos([video('a'), video('b'), video('c')]);
      await storage.setFavorites(['a', 'c', 'gone'], favorite: true);
      final favourites = {
        for (final v in await storage.getAllVideos())
          if (v.isFavorite) v.videoId,
      };
      expect(favourites, {'a', 'c'});

      await storage.setFavorites(['a'], favorite: false);
      expect(
        (await storage.getAllVideos())
            .where((v) => v.isFavorite)
            .map((v) => v.videoId),
        ['c'],
      );
    });

    test('deleted videos are forgotten, with their progress', () async {
      await storage.syncVideos([video('a'), video('b')]);
      await storage.savePlaybackPosition('a', const Duration(minutes: 1));
      await storage.removeVideos(['a']);

      expect((await storage.getAllVideos()).map((v) => v.videoId), ['b']);
      expect(await storage.getProgress('a'), isNull);
    });
  });

  group('fingerprint', skip: skip, () {
    test('saved with the videos; none before the first sync', () async {
      expect(await storage.videoCheckpoint(), isNull);
      await storage.syncVideos([video('a')], checkpoint: '1:a:100');
      expect(await storage.videoCheckpoint(), '1:a:100');
      expect(await storage.countVideos(), 1);
    });

    test("a refused (unconfirmed empty) sync doesn't save it", () async {
      await storage.syncVideos([video('a')], checkpoint: '1:a:100');
      await expectLater(
        storage.syncVideos(const [], checkpoint: '0'),
        throwsA(isA<MediaQueryException>()),
      );
      expect(await storage.videoCheckpoint(), '1:a:100');
    });

    test("doesn't touch the music library's own bookkeeping", () async {
      await isar.writeTxn(
        () => isar.libraryMetadataCollections.put(
          LibraryMetadataCollection()..songSyncCheckpoint = 'music-marker',
        ),
      );
      await storage.syncVideos([video('a')], checkpoint: '1:a:100');
      await storage.markVideosCheckedUnchanged();

      final row = await isar.libraryMetadataCollections.get(
        LibraryMetadataCollection.singletonId,
      );
      expect(row!.songSyncCheckpoint, 'music-marker');
      expect(row.videoSyncCheckpoint, '1:a:100');
      expect(row.lastVideoSyncAt, isNotNull);
    });
  });

  group('partial access', skip: skip, () {
    test(
      'videos the scan didn\'t see are kept, with their user data',
      () async {
        await storage.syncVideos([video('a'), video('b'), video('c')]);
        await storage.toggleFavorite('b');
        await storage.savePlaybackPosition('c', const Duration(minutes: 2));

        // The user let the app see only "a" (and a new one).
        final result = await storage.syncVideos([
          video('a'),
          video('d'),
        ], keepMissing: true);

        expect(result.removed, 0);
        expect(result.added, 1);
        final ids = {for (final v in await storage.getAllVideos()) v.videoId};
        expect(ids, {'a', 'b', 'c', 'd'});
        expect(
          (await storage.getAllVideos())
              .firstWhere((v) => v.videoId == 'b')
              .isFavorite,
          isTrue,
        );
        expect(await storage.getProgress('c'), isNotNull);
      },
    );
  });
}
