import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/favorites_local_storage.dart';
import 'package:melodix/core/database/music_local_storage.dart';
import 'package:melodix/core/database/song_library_update.dart';
import 'package:melodix/core/models/local_song.dart';
import 'package:melodix/core/preferences/library_filter.dart';

import '../../features/player/player_fixtures.dart';
import '../../support/isar_test_db.dart';

LocalSong _song(int id, String path, {int seconds = 180}) => LocalSong(
  id: id,
  title: 'Song $id',
  artist: 'Artist',
  album: 'Album',
  albumId: 1,
  duration: Duration(seconds: seconds),
  path: path,
  uri: 'content://media/external/audio/media/$id',
  size: 1000,
);

void main() {
  test('keeps songs long enough and outside turned-off folders', () {
    const filter = LibraryFilter(
      minSeconds: 60,
      excludedFolders: {'/music/WhatsApp'},
    );
    expect(filter.keeps(path: '/music/a.mp3', durationMs: 61000), isTrue);
    expect(filter.keeps(path: '/music/a.mp3', durationMs: 59000), isFalse);
    expect(
      filter.keeps(path: '/music/WhatsApp/Audio/v.mp3', durationMs: 90000),
      isFalse,
    );
    // Only that folder, not one whose name starts the same.
    expect(
      filter.keeps(path: '/music/WhatsAppBackup/v.mp3', durationMs: 90000),
      isTrue,
    );
    expect(LibraryFilter.folderOf('/music/rock/a.mp3'), '/music/rock');
  });

  test('saved and restored; a folder turned on and off', () {
    HydratedBloc.storage = MemoryStorage();
    final cubit = LibraryFilterCubit()
      ..setMinSeconds(120)
      ..setFolder('/music/voice', included: false);
    expect(cubit.state.excludedFolders, {'/music/voice'});
    expect(cubit.fromJson(cubit.toJson(cubit.state)!), cubit.state);
    cubit.setFolder('/music/voice', included: true);
    expect(cubit.state.excludedFolders, isEmpty);
    cubit.setMinSeconds(7); // not a choice
    expect(cubit.state.minSeconds, 120);
  });

  group('in storage', () {
    late Isar isar;
    var filter = LibraryFilter.defaults;
    final skip = isarLibraryPath() == null ? 'No Isar library' : false;

    setUp(() async {
      isar = await openTestIsar();
      filter = LibraryFilter.defaults;
    });
    tearDown(() => closeTestIsar(isar));

    test(
      'filtered songs leave the library, then come back with their data',
      () async {
        final storage = MusicLocalStorageImpl(isar, filter: () => filter);
        final favourites = FavoritesLocalStorageImpl(
          isar,
          filter: () => filter,
        );
        await storage.applyChanges(
          upserts: [
            _song(1, '/music/rock/a.mp3'),
            _song(2, '/music/voice/b.mp3'),
            _song(3, '/music/rock/short.mp3', seconds: 45),
          ],
          deletedIds: const [],
          checkpoint: 'cp',
        );
        await storage.toggleFavorite(2);
        await storage.recordPlay(2);

        final updates = <SongLibraryUpdate>[];
        final sub = storage.watchLibrary().listen(updates.add);

        /// Waits for the next library update (database reads finish off
        /// the event loop: a fixed number of microtasks isn't enough).
        Future<void> nextUpdate(int seen) async {
          while (updates.length <= seen) {
            await Future<void>.delayed(const Duration(milliseconds: 5));
          }
        }

        await nextUpdate(0); // the first load

        filter = const LibraryFilter(
          minSeconds: 60,
          excludedFolders: {'/music/voice'},
        );
        storage.reloadLibrary();
        await nextUpdate(1);
        final shown = (updates.last as SongLibraryLoaded).songs;
        expect([for (final s in shown) s.id], [1]);
        expect(await storage.countSongs(), 1);
        expect((await favourites.getFavorites()).songs, isEmpty);

        // Back on: the song returns, still a favourite, its play kept.
        filter = LibraryFilter.defaults;
        storage.reloadLibrary();
        await nextUpdate(2);
        final back = (updates.last as SongLibraryLoaded).songs;
        final voice = back.firstWhere((s) => s.id == 2);
        expect(voice.isFavorite, isTrue);
        expect(voice.playCount, 1);
        expect(back, hasLength(3));
        await sub.cancel();
      },
      skip: skip,
    );
  });
}
