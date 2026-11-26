import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/collections/library_metadata_collection.dart';
import 'package:melodix/core/database/collections/playlist_collection.dart';
import 'package:melodix/core/database/collections/recent_music_collection.dart';
import 'package:melodix/core/database/collections/song_collection.dart';
import 'package:melodix/core/database/music_local_storage.dart';
import 'package:melodix/core/database/playlist_local_storage.dart';
import 'package:melodix/core/errors/failures.dart';
import 'package:melodix/core/service/audio_library_delta_source.dart';
import 'package:melodix/core/service/permission_handling_service.dart';
import 'package:melodix/features/music_library/data/repositories/library_sync_repository_impl.dart';
import 'package:melodix/features/music_library/domain/entities/library_sync_result.dart';

import '../../../support/fake_media_store.dart';
import '../../../support/sync_repository_factory.dart';
import '../../../support/isar_test_db.dart';

/// Data-loss scenarios from the MediaStore permission / data-safety audit.
///
/// Every failure must leave the library exactly as it was: songs (including
/// hidden ones), favourites, play counts, playlists, recents and the sync
/// checkpoint. Real Isar, real storages; the device is [FakeMediaStore],
/// which follows MainActivity's channel contract.
void main() {
  final skip = isarLibraryPath() == null ? 'No Isar library' : false;

  late Isar isar;
  late MusicLocalStorageImpl storage;
  late PlaylistLocalStorageImpl playlists;
  late FakeMediaStore device;
  late LibrarySyncRepositoryImpl repository;

  setUp(() async {
    isar = await openTestIsar();
    storage = MusicLocalStorageImpl(isar);
    playlists = PlaylistLocalStorageImpl(isar);
    device = FakeMediaStore(volumes: ['external_primary', 'sd_card']);
    repository = buildSyncRepository(device: device, storage: storage);
  });

  tearDown(() => closeTestIsar(isar));

  Future<LibrarySyncResult> sync({bool force = false}) async =>
      (await repository.syncLibrary(force: force))
          .getOrElse(() => throw StateError('sync failed'));

  /// A synced library with user data on top: favourites, a hidden song, play
  /// counts / recents and two playlists (one favourited).
  Future<List<int>> seededWithUserData() async {
    final ids = [
      device.add(title: 'Alpha'),
      device.add(title: 'Bravo'),
      device.add(title: 'Charlie', volume: 'sd_card'),
      device.add(title: 'Delta', volume: 'sd_card'),
    ];
    await sync();
    await storage.toggleFavorite(ids[0]);
    await storage.setHidden(ids[1], hidden: true);
    await storage.recordPlay(ids[2]);
    await storage.recordPlay(ids[0]);
    final mix = await playlists.createPlaylist('Mix', songIds: ids);
    await playlists.toggleFavorite(mix);
    await playlists.createPlaylist('SD only', songIds: [ids[2], ids[3]]);
    return ids;
  }

  /// Everything the user could lose, in a comparable form.
  Future<Map<String, Object?>> snapshot() async {
    final songs = await isar.songCollections.where().findAll();
    final lists = await isar.playlistCollections.where().findAll();
    final recents = await isar.recentMusicCollections.where().findAll();
    final meta = await isar.libraryMetadataCollections.get(0);
    return {
      'songs': [
        for (final s in songs)
          '${s.id}|${s.title}|${s.path}|fav:${s.isFavorite}'
              '|hidden:${s.isHidden}|plays:${s.playCount}',
      ],
      'playlists': [
        for (final p in lists) '${p.name}|${p.songIds}|fav:${p.isFavorite}',
      ],
      'recents': [for (final r in recents) '${r.songId}@${r.playedAt}'],
      'checkpoint': meta?.songSyncCheckpoint,
      'syncedAt': meta?.lastSongSyncAt,
    };
  }

  /// Runs a sync that must fail with [failure] and change nothing.
  Future<void> expectSafeFailure<T extends Failure>({
    bool force = false,
  }) async {
    final before = await snapshot();
    expect(before['songs'], isNotEmpty);
    expect(before['checkpoint'], isNotNull);

    final result = await repository.syncLibrary(force: force);

    result.fold((f) => expect(f, isA<T>()), (r) => fail('expected $T, got $r'));
    expect(await snapshot(), before);
  }

  group('audit scenarios', () {
    test('1. genuinely empty MediaStore with valid permission', () async {
      // A fresh install on a device without music: a success, not an error.
      final first = await sync();
      expect(first.total, 0);
      expect(await storage.getSyncCheckpoint(), isNotNull);

      // The user deletes all their music: the confirmed-empty answer
      // (every query succeeded, MediaStore counts 0) is applied.
      final id = device.add(title: 'Alpha');
      await sync();
      await playlists.createPlaylist('Mix', songIds: [id]);
      device.delete(id);

      final emptied = await sync();

      expect(emptied.removed, 1);
      expect(emptied.total, 0);
      expect((await playlists.getAllPlaylists()).single.songIds, isEmpty);

      // And the same through a forced (full) scan.
      final bravo = device.add(title: 'Bravo');
      expect((await sync()).total, 1);
      device.delete(bravo);
      final full = await sync(force: true);
      expect(full.total, 0);
    }, skip: skip);

    test('2. permission denied before the first sync', () async {
      device.add(title: 'Alpha');
      device.permission = MediaPermissionStatus.denied;

      final result = await repository.syncLibrary();

      result.fold(
        (f) => expect(
          f,
          isA<PermissionFailure>().having(
            (p) => p.permanentlyDenied,
            'permanentlyDenied',
            isFalse,
          ),
        ),
        (r) => fail('expected PermissionFailure, got $r'),
      );
      expect(device.nativeCalls, isEmpty); // not even a checkpoint read
      expect(await storage.getSyncCheckpoint(), isNull);
      expect(await storage.getAllSongIds(), isEmpty);
    }, skip: skip);

    group('3. permission revoked after a successful sync', () {
      test('reported by permission_handler', () async {
        await seededWithUserData();
        device
          ..permission = MediaPermissionStatus.permanentlyDenied
          ..nativeCalls.clear();

        await expectSafeFailure<PermissionFailure>();
        await expectSafeFailure<PermissionFailure>(force: true);
        // Stopped before MediaStore was queried at all.
        expect(device.nativeCalls, isEmpty);
      }, skip: skip);

      test('reported only by the native check (revoked mid-sync)', () async {
        await seededWithUserData();
        device.nativePermission = false;

        await expectSafeFailure<PermissionFailure>();
        await expectSafeFailure<PermissionFailure>(force: true);
      }, skip: skip);
    });

    test('4. SecurityException during the changed-files query', () async {
      final ids = await seededWithUserData();
      device.add(title: 'Echo');
      device.delete(ids[0]);
      device.changedQueryFault = NativeFault.securityException;

      await expectSafeFailure<PermissionFailure>();
      expect(device.fullScans, 1, reason: 'no full-scan fallback');
    }, skip: skip);

    test('5. SecurityException during the ids-only deletion query', () async {
      final ids = await seededWithUserData();
      device.delete(ids[3]);
      device.idsQueryFault = NativeFault.securityException;

      await expectSafeFailure<PermissionFailure>();
      expect(device.fullScans, 1, reason: 'no full-scan fallback');

      // A null cursor on the same query is a query failure, also safe.
      device.idsQueryFault = NativeFault.nullCursor;
      await expectSafeFailure<LibraryFailure>();
    }, skip: skip);

    test('6. failure while querying one of several volumes', () async {
      final ids = await seededWithUserData();
      device.add(title: 'New on phone'); // primary volume: readable
      device.modify(ids[2], title: 'Charlie 2'); // SD card: unreadable
      device.unavailableVolume = 'sd_card';

      await expectSafeFailure<LibraryFailure>();
      expect(device.fullScans, 1, reason: 'no full-scan fallback');
    }, skip: skip);

    group('7. failed full scan', () {
      test('native scan: null cursor', () async {
        await seededWithUserData();
        device.fullScanFault = NativeFault.nullCursor;

        await expectSafeFailure<LibraryFailure>(force: true);
      }, skip: skip);

      test('native scan: SecurityException', () async {
        await seededWithUserData();
        device.fullScanFault = NativeFault.securityException;

        await expectSafeFailure<PermissionFailure>(force: true);
      }, skip: skip);

      test('native scan: failed count query', () async {
        await seededWithUserData();
        device.checkpointFault = NativeFault.nullCursor;

        await expectSafeFailure<LibraryFailure>(force: true);
        await expectSafeFailure<LibraryFailure>();
      }, skip: skip);

      test('on_audio_query scan: failure looks like an empty list', () async {
        // No native scan and no generations (e.g. another platform): the
        // plugin's null cursor gives [], which must not wipe the library.
        await seededWithUserData();
        device
          ..nativeFullScan = false
          ..supportsGenerations = false
          ..fullScanFault = NativeFault.nullCursor;

        final before = await snapshot();
        final result = await repository.syncLibrary(force: true);

        expect(result.isLeft(), isTrue);
        expect(await snapshot(), before);
      }, skip: skip);
    });

    test('8. sync succeeds after permission is restored', () async {
      final ids = await seededWithUserData();
      final checkpoint = await storage.getSyncCheckpoint();
      device.permission = MediaPermissionStatus.denied;
      final added = device.add(title: 'Echo');
      device.delete(ids[3]);
      await expectSafeFailure<PermissionFailure>();

      device.permission = MediaPermissionStatus.granted;
      final result = await sync();

      // Incremental from the untouched checkpoint: the changes made while
      // access was denied are applied, user data is kept.
      expect(result.incremental, isTrue);
      expect(result.added, 1);
      expect(result.removed, 1);
      expect(await storage.getSyncCheckpoint(), isNot(checkpoint));
      final echo = await isar.songCollections.get(added);
      expect(echo!.title, 'Echo');
      final alpha = await isar.songCollections.get(ids[0]);
      expect(alpha!.isFavorite, isTrue);
      expect(alpha.playCount, 1);
      expect((await isar.songCollections.get(ids[1]))!.isHidden, isTrue);
      final lists = {
        for (final p in await playlists.getAllPlaylists()) p.name: p,
      };
      expect(lists['Mix']!.songIds, ids.take(3).toList());
      expect(lists['Mix']!.isFavorite, isTrue);
      expect(lists['SD only']!.songIds, [ids[2]]);
    }, skip: skip);
  });

  group('defence in depth', () {
    test('no ids while MediaStore counts rows is a failure', () async {
      await seededWithUserData();
      // Simulates a device that answers the ids query with an empty cursor
      // although the count query sees rows.
      final before = await snapshot();
      final broken = _EmptyIdsDevice(device);
      final repo = buildSyncRepository(
        device: device,
        storage: storage,
        deltaSource: broken,
      );
      device.add(title: 'Echo'); // so the plan is incremental

      final result = await repo.syncLibrary();

      expect(result.isLeft(), isTrue);
      expect(await snapshot(), before);
    }, skip: skip);

    test('native scan with no rows while MediaStore counts some', () async {
      await seededWithUserData();
      final before = await snapshot();
      final repo = buildSyncRepository(
        device: device,
        storage: storage,
        deltaSource: _EmptyIdsDevice(device),
      );

      final result = await repo.syncLibrary(force: true);

      expect(result.isLeft(), isTrue);
      expect(await snapshot(), before);
    }, skip: skip);
  });
}

/// Wraps a device but drops every id / row from its answers (keeping the
/// checkpoint's count), like a query that silently returned nothing.
class _EmptyIdsDevice extends FakeMediaStore {
  _EmptyIdsDevice(this._inner);

  final FakeMediaStore _inner;

  @override
  Future<MediaStoreCheckpoint?> currentCheckpoint() =>
      _inner.currentCheckpoint();

  @override
  Future<AudioLibraryChanges> changesSince(Map<String, int> since) async {
    final real = await _inner.changesSince(since);
    return AudioLibraryChanges(
      checkpoint: real.checkpoint,
      changed: real.changed,
      allIds: const {},
    );
  }

  @override
  Future<AudioFullScan?> fullScan() async {
    final real = await _inner.fullScan();
    return AudioFullScan(checkpoint: real!.checkpoint, records: const []);
  }
}
