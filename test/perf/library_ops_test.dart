import 'package:flutter_test/flutter_test.dart';
import 'package:melodix/features/music_library/data/datasources/music_local_storage.dart';
import 'package:melodix/features/music_library/data/datasources/playlist_local_storage.dart';
import 'package:melodix/features/music_library/data/models/local_song.dart';
import 'package:melodix/features/music_library/data/datasources/music_service.dart';
import 'package:melodix/core/utils/debug_counters.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/presentation/logic/library_search_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fake_media_store.dart';
import '../support/sync_repository_factory.dart';
import '../support/isar_test_db.dart';

class MockMusicService extends Mock implements MusicService {}

class MockStorage extends Mock implements MusicLocalStorage {}

class MockPlaylists extends Mock implements PlaylistLocalStorage {}

void main() {
  setUpAll(() => registerFallbackValue(<LocalSong>[]));

  // Baseline before the optimisation: 10 searches = 10 full library reads +
  // 10 playlist reads (each also regrouping albums and artists).
  test('10 searches read nothing from the database', () async {
    final storage = MockStorage();
    final cubit = LibrarySearchCubit(debounce: Duration.zero)
      ..updateSources(
        songs: [
          for (var i = 1; i <= 500; i++)
            Song(
              id: i,
              title: 'Track $i',
              artist: 'Artist',
              album: 'Album',
              albumId: 1,
              duration: const Duration(minutes: 3),
              path: '/m/$i.mp3',
              playbackUri: Uri.parse('content://x/$i'),
              isFavorite: false,
              playCount: 0,
            ),
        ],
      );
    DebugCounters.reset();

    for (final q in [
      't',
      'tr',
      'tra',
      'trac',
      'track',
      'track 1',
      'track 12',
      'track 1',
      'track',
      'gym',
    ]) {
      cubit.queryChanged(q);
      await Future<void>.delayed(Duration.zero);
    }

    verifyZeroInteractions(storage);
    expect(DebugCounters.of('searchRun'), 10);
    expect(cubit.state.results.songs, isEmpty); // 'gym'
    await cubit.close();
  });

  // Baseline before the optimisation: 3 syncs with nothing changed = 3 full
  // MediaStore scans + 3 database diffs.
  test('syncs with nothing changed do no MediaStore scan', () async {
    final isar = await openTestIsar();
    addTearDown(() => closeTestIsar(isar));
    final device = FakeMediaStore();
    for (var i = 0; i < 500; i++) {
      device.add(title: 'Track $i');
    }
    final repo = buildSyncRepository(
      device: device,
      storage: MusicLocalStorageImpl(isar),
    );
    await repo.syncLibrary(); // first sync on this device: full scan
    DebugCounters.reset();

    for (var i = 0; i < 3; i++) {
      await repo.syncLibrary();
    }

    expect(DebugCounters.of('mediaStoreScan'), 0);
    expect(DebugCounters.of('mediaStoreDelta'), 0);
    expect(device.fullScans, 1);
  }, skip: isarLibraryPath() == null ? 'No Isar library' : false);
}
