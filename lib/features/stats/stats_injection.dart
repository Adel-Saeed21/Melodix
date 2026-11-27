import 'package:get_it/get_it.dart';
import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/listening_history_local_storage.dart';
import 'package:melodix/features/stats/data/repositories/listening_history_repository_impl.dart';
import 'package:melodix/features/stats/domain/repositories/listening_history_repository.dart';
import 'package:melodix/features/stats/domain/usecases/watch_listening_stats_usecase.dart';
import 'package:melodix/features/stats/presentation/logic/listening_stats_cubit.dart';

/// Listening stats: read from the whole history, whatever the filters show.
void registerStats(GetIt getIt) {
  getIt
    ..registerLazySingleton<ListeningHistoryLocalStorage>(
      () => ListeningHistoryLocalStorageImpl(getIt<Isar>()),
    )
    ..registerLazySingleton<ListeningHistoryRepository>(
      () => ListeningHistoryRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => WatchListeningStatsUseCase(getIt()))
    // Per visit: reads the history while the page is open.
    ..registerFactory(() => ListeningStatsCubit(getIt()));
}
