import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/collections/song_collection.dart';
import 'package:melodix/core/database/music_local_storage.dart';
import 'package:melodix/core/models/local_song.dart';
import 'package:melodix/core/service/app_lifecycle_service.dart';
import 'package:melodix/features/music_library/data/mappers/song_mapper.dart';
import 'package:melodix/features/music_library/data/repositories/catalog_repository_impl.dart';
import 'package:melodix/features/music_library/data/repositories/song_repository_impl.dart';
import 'package:melodix/features/music_library/domain/entities/library_permission.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/domain/usecases/check_library_permission_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_last_library_sync_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/open_library_settings_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/request_library_permission_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/sync_music_library_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_library_songs_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/library_collections_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_event.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_state.dart';
import 'package:mocktail/mocktail.dart';

import '../support/isar_test_db.dart';
import 'library_updates_perf_support.dart';

class _Check extends Mock implements CheckLibraryPermissionUseCase {}

class _Request extends Mock implements RequestLibraryPermissionUseCase {}

class _Sync extends Mock implements SyncMusicLibraryUseCase {}

class _LastSync extends Mock implements GetLastLibrarySyncUseCase {}

class _Settings extends Mock implements OpenLibrarySettingsUseCase {}

class _Lifecycle implements AppLifecycleService {
  @override
  Stream<void> get onResumed => const Stream.empty();
}

/// Storage that counts reads of the whole library: Isar queries issued by
/// the app and song rows delivered to it.
class CountingStorage extends MusicLocalStorageImpl {
  CountingStorage(super.isar);

  int fullReads = 0;
  int rowsRead = 0;

  void reset() => fullReads = rowsRead = 0;

  List<SongCollection> _count(List<SongCollection> rows) {
    fullReads++;
    rowsRead += rows.length;
    return rows;
  }

  @override
  Future<List<SongCollection>> getAllSongs() async =>
      _count(await super.getAllSongs());
}

/// Measures play / favourite / hide and album+artist rebuilding on 10,000
/// songs through the real storage, repositories and bloc (real Isar).
void main() {
  final skip = isarLibraryPath() == null ? 'No Isar library' : false;
  const songCount = 10000;
  const runs = 7;

  late Isar isar;
  late CountingStorage storage;
  late MusicLibraryBloc bloc;
  late SongRepositoryImpl songs;

  setUp(() async {
    isar = await openTestIsar();
    storage = CountingStorage(isar);
    await storage.syncSongs([
      for (var i = 1; i <= songCount; i++)
        LocalSong(
          id: i,
          title: 'Song ${i.toString().padLeft(5, '0')}',
          artist: 'Artist ${i % 200}',
          album: 'Album ${i % 500}',
          albumId: i % 500,
          duration: Duration(seconds: 120 + i % 180),
          path: '/music/$i.mp3',
          uri: 'content://media/external/audio/media/$i',
          size: 1000,
        ),
    ]);
    const mapper = SongMapper(isAndroid: true);
    songs = SongRepositoryImpl(
      storage: storage,
      musicService: NoMusicService(),
      mapper: mapper,
    );
    final check = _Check();
    final lastSync = _LastSync();
    when(() => check()).thenAnswer((_) async => LibraryPermission.denied);
    when(() => lastSync()).thenAnswer((_) async => null);
    bloc = buildBloc(
      check: check,
      request: _Request(),
      sync: _Sync(),
      lastSync: lastSync,
      settings: _Settings(),
      lifecycle: _Lifecycle(),
      watch: WatchLibrarySongsUseCase(songs),
      songRepository: songs,
    );
    bloc.add(const MusicLibraryStarted());
    await bloc.stream.firstWhere((s) => s.songs.length == songCount);
    await settle();
  });

  tearDown(() async {
    await bloc.close();
    await closeTestIsar(isar);
  });

  /// Runs [op] and waits until the bloc state satisfies [done]. Returns the
  /// time, Isar full-library reads, rows read and bloc emissions.
  Future<Sample> measure(
    Future<void> Function() op,
    bool Function(MusicLibraryState) done,
  ) async {
    storage.reset();
    var emissions = 0;
    final sub = bloc.stream.listen((_) => emissions++);
    final sw = Stopwatch()..start();
    final reached = bloc.stream.firstWhere(done);
    await op();
    if (!done(bloc.state)) await reached;
    sw.stop();
    await settle(); // let any late (unnecessary) reload arrive and count it
    await sub.cancel();
    return Sample(
      sw.elapsedMicroseconds / 1000,
      storage.fullReads,
      storage.rowsRead,
      emissions,
    );
  }

  Song songAt(int id) => bloc.state.songs.firstWhere((s) => s.id == id);

  test(
    'play / favourite / hide on 10,000 songs',
    () async {
      final play = <Sample>[];
      for (var i = 0; i < runs; i++) {
        final id = 5000 + i;
        final before = songAt(id).playCount;
        // Same call the player makes when a song starts.
        play.add(
          await measure(
            () => storage.recordPlay(id),
            (s) => s.songs.any((x) => x.id == id && x.playCount == before + 1),
          ),
        );
      }

      final favourite = <Sample>[];
      for (var i = 0; i < runs; i++) {
        final id = 6000 + i;
        favourite.add(
          await measure(
            () => songs.toggleFavorite(id),
            (s) => s.songs.any((x) => x.id == id && x.isFavorite),
          ),
        );
      }

      final hide = <Sample>[];
      for (var i = 0; i < runs; i++) {
        final id = 7000 + i;
        hide.add(
          await measure(
            () => songs.setSongHidden(id, hidden: true),
            (s) => !s.songs.any((x) => x.id == id),
          ),
        );
      }

      report('play (recordPlay)', play);
      report('favourite toggle', favourite);
      report('hide song', hide);
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'albums + artists rebuild on 10,000 songs',
    () async {
      final catalog = CatalogRepositoryImpl(
        storage: storage,
        mapper: const SongMapper(isAndroid: true),
      );
      final samples = <Sample>[];
      for (var i = 0; i < runs; i++) {
        final cubit = buildCollectionsCubit(catalog);
        storage.reset();
        final sw = Stopwatch()..start();
        // First call: albums / artists are built (a real library change).
        await cubit.onLibraryChanged(bloc.state.songs);
        sw.stop();
        expect(cubit.state.status, LoadStatus.ready);
        expect(cubit.state.albums, hasLength(500));
        expect(cubit.state.artists, hasLength(200));
        samples.add(
          Sample(
            sw.elapsedMicroseconds / 1000,
            storage.fullReads,
            storage.rowsRead,
            1,
          ),
        );
        await cubit.close();
      }
      report('albums + artists rebuild', samples);
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
