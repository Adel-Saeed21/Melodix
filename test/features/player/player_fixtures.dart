import 'package:melodix/features/player/domain/usecases/edit_queue_usecase.dart';

import 'dart:async';

import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/domain/entities/playback_progress.dart';
import 'package:melodix/features/player/domain/usecases/play_queue_usecase.dart';
import 'package:melodix/features/player/domain/usecases/playback_controls_usecase.dart';
import 'package:melodix/features/player/domain/usecases/restore_playback_session_usecase.dart';
import 'package:melodix/features/player/domain/usecases/watch_now_playing_usecase.dart';
import 'package:melodix/features/player/domain/usecases/watch_playback_progress_usecase.dart';
import 'package:melodix/features/player/presentation/logic/playback_progress_cubit.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class MockEditQueue extends Mock implements EditQueueUseCase {}

class MockWatch extends Mock implements WatchNowPlayingUseCase {}

class MockPlayQueue extends Mock implements PlayQueueUseCase {}

class MockControls extends Mock implements PlaybackControlsUseCase {}

class MockRestore extends Mock implements RestorePlaybackSessionUseCase {}

class MockWatchProgress extends Mock implements WatchPlaybackProgressUseCase {}

Song playerSong(int id, {String? title}) => Song(
  id: id,
  title: title ?? 'Song $id',
  artist: 'Artist $id',
  album: 'Album',
  albumId: 1,
  duration: const Duration(minutes: 4, seconds: 15),
  path: '/m/$id.mp3',
  playbackUri: Uri.parse('content://media/external/audio/media/$id'),
  isFavorite: false,
  playCount: 0,
);

/// A real [PlayerCubit] driven by a fake player stream.
class PlayerHarness {
  PlayerHarness([NowPlaying initial = NowPlaying.idle]) {
    when(() => watch.current).thenReturn(initial);
    when(() => watch()).thenAnswer((_) => states.stream);
    when(() => watchProgress.current).thenReturn(PlaybackProgress.zero);
    when(() => watchProgress()).thenAnswer((_) => progressStates.stream);
    progressCubit = PlaybackProgressCubit(watchProgress);
    for (final call in <Future<void> Function()>[
      controls.play,
      controls.pause,
      controls.next,
      controls.previous,
    ]) {
      when(call).thenAnswer((_) async {});
    }
    when(() => controls.seek(any())).thenAnswer((_) async {});
    when(() => controls.skipToIndex(any())).thenAnswer((_) async {});
    when(() => controls.setRepeatMode(any())).thenAnswer((_) async {});
    when(() => controls.setShuffle(any())).thenAnswer((_) async {});
    when(() => playQueue(any())).thenAnswer((_) async {});
    when(() => restore()).thenAnswer((_) async {});
    when(() => editQueue.playNext(any())).thenAnswer((_) async {});
    when(() => editQueue.addToQueue(any())).thenAnswer((_) async {});
    cubit = PlayerCubit(
      watchNowPlaying: watch,
      playQueue: playQueue,
      controls: controls,
      restore: restore,
      editQueue: editQueue,
    );
  }

  final states = StreamController<NowPlaying>.broadcast();

  /// "Play next" / "Add to queue".
  final editQueue = MockEditQueue();

  /// Position ticks (their own stream, like the real player).
  final progressStates = StreamController<PlaybackProgress>.broadcast();
  final watchProgress = MockWatchProgress();
  late final PlaybackProgressCubit progressCubit;
  final watch = MockWatch();
  final playQueue = MockPlayQueue();
  final controls = MockControls();
  final restore = MockRestore();
  late final PlayerCubit cubit;

  Future<void> emit(NowPlaying state) async {
    states.add(state);
    await Future<void>.delayed(Duration.zero);
  }

  /// The player is [position] into a song of [duration].
  void tick(
    Duration position, {
    Duration duration = const Duration(minutes: 4, seconds: 15),
  }) => progressStates.add(
    PlaybackProgress(position: position, duration: duration),
  );

  /// [child] with both player cubits above it, as the app provides them.
  Widget provide(Widget child) => MultiBlocProvider(
    providers: [
      BlocProvider<PlayerCubit>.value(value: cubit),
      BlocProvider<PlaybackProgressCubit>.value(value: progressCubit),
    ],
    child: child,
  );

  Future<void> dispose() async {
    await cubit.close();
    await progressCubit.close();
    await states.close();
    await progressStates.close();
  }
}

void registerPlayerFallbacks() {
  registerFallbackValue(Duration.zero);
  registerFallbackValue(PlaybackRepeat.off);
  registerFallbackValue(const PlayQueueParams([]));
  registerFallbackValue(playerSong(0));
  registerFallbackValue(<Song>[]);
}
