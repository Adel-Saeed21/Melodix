import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/features/player/domain/entities/playback_progress.dart';
import 'package:melodix/features/player/domain/usecases/watch_playback_progress_usecase.dart';

/// Where playback is in the current song, app-wide. Only the widgets that
/// show it listen (seek bar, times, ⏮'s "restart the song"); everything
/// else follows [PlayerCubit], which doesn't change on position ticks.
class PlaybackProgressCubit extends Cubit<PlaybackProgress> {
  PlaybackProgressCubit(WatchPlaybackProgressUseCase watchProgress)
    : super(watchProgress.current) {
    _subscription = watchProgress().listen((progress) {
      if (!isClosed) emit(progress);
    });
  }

  late final StreamSubscription<PlaybackProgress> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
