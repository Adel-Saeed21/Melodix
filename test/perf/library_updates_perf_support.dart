import 'dart:typed_data';

import 'package:melodix/features/music_library/data/models/local_song.dart';
import 'package:melodix/core/service/app_lifecycle_service.dart';
import 'package:melodix/features/music_library/data/datasources/music_service.dart';
import 'package:melodix/features/music_library/data/repositories/song_repository_impl.dart';
import 'package:melodix/features/music_library/domain/usecases/check_library_permission_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/build_library_catalog_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_last_library_sync_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/open_library_settings_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/request_library_permission_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/sync_music_library_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_library_songs_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/library_collections_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_library_sync_stage_usecase.dart';
import 'package:melodix/features/music_library/domain/entities/library_sync_stage.dart';

/// The parts of the benchmark that depend on constructor signatures.
MusicLibraryBloc buildBloc({
  required CheckLibraryPermissionUseCase check,
  required RequestLibraryPermissionUseCase request,
  required SyncMusicLibraryUseCase sync,
  required GetLastLibrarySyncUseCase lastSync,
  required OpenLibrarySettingsUseCase settings,
  required AppLifecycleService lifecycle,
  required WatchLibrarySongsUseCase watch,
  required SongRepositoryImpl songRepository,
}) => MusicLibraryBloc(
  checkPermission: check,
  requestPermission: request,
  syncLibrary: sync,
  getLastSync: lastSync,
  watchSongs: watch,
  watchSyncStage: _NoStages(),
  lifecycle: lifecycle,
  openSettings: settings,
);

/// Albums / artists are built from the songs in memory (no database).
LibraryCollectionsCubit buildCollectionsCubit() =>
    LibraryCollectionsCubit(buildCatalog: const BuildLibraryCatalogUseCase());

class Sample {
  const Sample(this.ms, this.fullReads, this.rowsRead, this.emissions);

  final double ms;
  final int fullReads;
  final int rowsRead;
  final int emissions;
}

/// Lets queued Isar notifications and stream events arrive.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 60));

void report(String name, List<Sample> samples) {
  final times = [for (final s in samples) s.ms]..sort();
  final median = times[times.length ~/ 2];
  final last = samples.last;
  // ignore: avoid_print
  print(
    'PERF $name: median ${median.toStringAsFixed(1)} ms '
    '(min ${times.first.toStringAsFixed(1)}, max ${times.last.toStringAsFixed(1)}) | '
    'full-library reads ${last.fullReads}, rows read ${last.rowsRead}, '
    'bloc emissions ${last.emissions}',
  );
}

class NoMusicService implements MusicService {
  @override
  bool get canDeleteSongs => false;
  @override
  Future<List<int>> deleteSongs(List<int> songIds) async => const [];
  @override
  Future<List<LocalSong>> getAllSongs() async => const [];
  @override
  Future<Uint8List?> getArtwork(int songId, {int size = 200}) async => null;
}

/// Never reports a stage (these tests don't look at progress).
class _NoStages implements WatchLibrarySyncStageUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Stream<LibrarySyncStage> call() => const Stream.empty();
}
