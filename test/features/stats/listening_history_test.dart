import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/collections/song_collection.dart';
import 'package:melodix/core/database/listening_history_local_storage.dart';
import 'package:melodix/core/database/music_local_storage.dart';
import 'package:melodix/core/models/local_song.dart';
import 'package:melodix/core/preferences/library_filter.dart';
import 'package:melodix/features/stats/data/repositories/listening_history_repository_impl.dart';
import 'package:melodix/features/stats/domain/listening_stats.dart';
import 'package:melodix/features/stats/domain/usecases/watch_listening_stats_usecase.dart';
import 'package:melodix/features/stats/presentation/logic/listening_stats_cubit.dart';

import '../../support/isar_test_db.dart';

LocalSong _song(int id, {required String folder, int seconds = 180}) =>
    LocalSong(
      id: id,
      title: 'Song $id',
      artist: 'Artist $id',
      album: 'Album',
      albumId: 1,
      duration: Duration(seconds: seconds),
      path: '/music/$folder/$id.mp3',
      uri: 'content://media/external/audio/media/$id',
      size: 1000,
    );

void main() {
  final skip = isarLibraryPath() == null ? 'No Isar library' : false;

  late Isar isar;
  late MusicLocalStorage music;
  var filter = LibraryFilter.defaults;
  late WatchListeningStatsUseCase watchStats;

  setUp(() async {
    isar = await openTestIsar();
    filter = LibraryFilter.defaults;
    music = MusicLocalStorageImpl(isar, filter: () => filter);
    watchStats = WatchListeningStatsUseCase(
      ListeningHistoryRepositoryImpl(ListeningHistoryLocalStorageImpl(isar)),
    );
    await music.applyChanges(
      upserts: [
        _song(1, folder: 'Rock'),
        _song(2, folder: 'Podcasts'),
        _song(3, folder: 'Rock', seconds: 45),
      ],
      deletedIds: const [],
      checkpoint: 'cp',
    );
    for (final id in [1, 2, 2, 3]) {
      await music.recordPlay(id);
    }
    await music.addListening(1, const Duration(seconds: 100));
    await music.addListening(2, const Duration(seconds: 200));
    await music.addListening(3, const Duration(seconds: 40));
  });

  tearDown(() => closeTestIsar(isar));

  Future<ListeningStats> stats() => watchStats().first;

  test('the stats ignore the music filters', () async {
    final before = await stats();
    expect(before.plays, 4);
    expect(before.listened, const Duration(seconds: 340));

    // Hide a folder and every song under 2 minutes.
    filter = const LibraryFilter(
      minSeconds: 120,
      excludedFolders: {'/music/Podcasts'},
    );
    expect(await music.countSongs(), 1, reason: 'the library is filtered');

    final after = await stats();
    expect(after, before, reason: 'the history is not');
  }, skip: skip);

  test('deleted songs stay in the history', () async {
    await music.removeSongs([2]);

    final s = await stats();
    expect(s.plays, 4);
    expect(s.listened, const Duration(seconds: 340));
    expect(s.topSongs.first.id, 2);
    expect(s.topSongs.first.inLibrary, isFalse);
    expect(s.songCount, 2, reason: 'no longer in the library');
  }, skip: skip);

  test('old rows count with their estimate (plays × length)', () async {
    final r = (await isar.songCollections.get(1))!;
    await isar.writeTxn(
      () => isar.songCollections.put(
        r
          ..playCount = 3
          ..listenedMs = null,
      ),
    );

    final s = await stats();
    // Song 1: 3 × 3 min = 540 s, estimated; songs 2 and 3 as heard.
    expect(s.listened, const Duration(seconds: 540 + 200 + 40));
  }, skip: skip);

  test('the cubit follows new listening live', () async {
    final cubit = ListeningStatsCubit(watchStats);
    await expectLater(
      cubit.stream,
      emits(isA<ListeningStats>().having((s) => s.plays, 'plays', 4)),
    );

    await music.recordPlay(1);
    await expectLater(
      cubit.stream,
      emits(isA<ListeningStats>().having((s) => s.plays, 'plays', 5)),
    );
    await cubit.close();
  }, skip: skip);
}
