import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/features/stats/domain/listening_stats.dart';
import 'package:melodix/features/stats/domain/usecases/watch_listening_stats_usecase.dart';

/// The stats page's state: null until the history is read, then live.
class ListeningStatsCubit extends Cubit<ListeningStats?> {
  ListeningStatsCubit(WatchListeningStatsUseCase watchStats) : super(null) {
    _subscription = watchStats().listen(
      emit,
      // Unreadable: show what was there (or nothing yet), don't crash.
      onError: (Object _) {
        if (state == null) emit(ListeningStats.empty);
      },
    );
  }

  late final StreamSubscription<ListeningStats> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
