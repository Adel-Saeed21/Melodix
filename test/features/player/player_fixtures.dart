import 'dart:async';

import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/domain/usecases/play_queue_usecase.dart';
import 'package:melodix/features/player/domain/usecases/playback_controls_usecase.dart';
import 'package:melodix/features/player/domain/usecases/restore_playback_session_usecase.dart';
import 'package:melodix/features/player/domain/usecases/watch_now_playing_usecase.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockWatch extends Mock implements WatchNowPlayingUseCase {}

class MockPlayQueue extends Mock implements PlayQueueUseCase {}

class MockControls extends Mock implements PlaybackControlsUseCase {}

class MockRestore extends Mock implements RestorePlaybackSessionUseCase {}

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
    cubit = PlayerCubit(
      watchNowPlaying: watch,
      playQueue: playQueue,
      controls: controls,
      restore: restore,
    );
  }

  final states = StreamController<NowPlaying>.broadcast();
  final watch = MockWatch();
  final playQueue = MockPlayQueue();
  final controls = MockControls();
  final restore = MockRestore();
  late final PlayerCubit cubit;

  Future<void> emit(NowPlaying state) async {
    states.add(state);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> dispose() async {
    await cubit.close();
    await states.close();
  }
}

void registerPlayerFallbacks() {
  registerFallbackValue(Duration.zero);
  registerFallbackValue(PlaybackRepeat.off);
  registerFallbackValue(const PlayQueueParams([]));
}
