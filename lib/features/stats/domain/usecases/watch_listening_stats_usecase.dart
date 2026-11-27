import 'package:melodix/features/stats/domain/listening_stats.dart';
import 'package:melodix/features/stats/domain/repositories/listening_history_repository.dart';

/// The listening stats, now and whenever plays or listening change.
class WatchListeningStatsUseCase {
  const WatchListeningStatsUseCase(this._repository);

  final ListeningHistoryRepository _repository;

  Stream<ListeningStats> call() =>
      _repository.watchHistory().map(ListeningStats.of);
}
