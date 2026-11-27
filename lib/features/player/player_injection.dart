import 'package:flutter/foundation.dart';

import 'package:get_it/get_it.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:melodix/features/player/data/audio_settings_binder.dart';
import 'package:melodix/features/player/data/equalizer/android_equalizer_engine.dart';
import 'package:melodix/features/player/domain/repositories/equalizer_engine.dart';
import 'package:melodix/features/player/presentation/logic/audio_settings_cubit.dart';
import 'package:melodix/features/player/presentation/logic/sleep_timer_cubit.dart';
import 'package:melodix/features/player/presentation/logic/cover_accent_cubit.dart';
import 'package:melodix/features/player/data/datasources/playback_state_local_storage.dart';
import 'package:melodix/features/music_library/data/mappers/song_mapper.dart';
import 'package:melodix/features/player/data/repositories/player_repository_impl.dart';
import 'package:melodix/features/player/domain/repositories/player_repository.dart';
import 'package:melodix/features/player/domain/usecases/play_queue_usecase.dart';
import 'package:melodix/features/player/domain/usecases/edit_queue_usecase.dart';
import 'package:melodix/features/player/domain/usecases/playback_controls_usecase.dart';
import 'package:melodix/features/player/domain/usecases/restore_playback_session_usecase.dart';
import 'package:melodix/features/player/domain/usecases/watch_now_playing_usecase.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';
import 'package:melodix/features/player/data/session/storage_play_recorder.dart';
import 'package:melodix/features/player/presentation/logic/playback_progress_cubit.dart';
import 'package:melodix/features/player/domain/usecases/watch_playback_progress_usecase.dart';
import 'package:melodix/features/music_library/data/datasources/music_local_storage.dart';
import 'package:melodix/features/music_library/domain/usecases/get_song_artwork_usecase.dart';

/// Music playback: the audio player, equalizer and audio settings, sleep
/// timer, and the app-wide player state (mini and full player).
void registerPlayer(GetIt getIt) {
  // The app's only audio player instance. No audio effects in it: an
  // effect is switched on inside every song load, so one failing on a
  // phone would stop every song from playing.
  getIt.registerLazySingleton<AudioPlayer>(AudioPlayer.new);
  // The phone's equalizer (Android), on the player's audio session but
  // outside the player (see AndroidEqualizerEngine).
  getIt.registerLazySingleton<EqualizerEngine>(
    () => defaultTargetPlatform == TargetPlatform.android
        ? AndroidEqualizerEngine(
            audioSessionIds: getIt<AudioPlayer>().androidAudioSessionIdStream,
          )
        : const UnsupportedEqualizerEngine(),
    dispose: (engine) async {
      if (engine is AndroidEqualizerEngine) await engine.dispose();
    },
  );
  // Speed, skip silence and the equalizer, saved; applied by the binder
  // (started by [startAudioSettings]).
  getIt.registerLazySingleton<AudioSettingsCubit>(
    AudioSettingsCubit.new,
    dispose: (cubit) => cubit.close(),
  );
  getIt.registerLazySingleton<AudioSettingsBinder>(
    () => AudioSettingsBinder(
      settings: getIt<AudioSettingsCubit>().stream,
      initial: getIt<AudioSettingsCubit>().state,
      player: getIt<PlayerRepository>(),
      equalizer: getIt<EqualizerEngine>(),
    ),
    dispose: (binder) => binder.dispose(),
  );
  getIt.registerLazySingleton<SleepTimerCubit>(
    () => SleepTimerCubit(getIt<PlayerRepository>()),
    dispose: (cubit) => cubit.close(),
  );

  getIt.registerLazySingleton<PlayerRepository>(
    () => PlayerRepositoryImpl(
      player: getIt<AudioPlayer>(),
      sessionStorage: getIt<PlaybackStateLocalStorage>(),
      playRecorder: StoragePlayRecorder(getIt<MusicLocalStorage>()),
      mapper: getIt<SongMapper>(),
    ),
  );

  getIt
    ..registerLazySingleton(
      () => WatchNowPlayingUseCase(getIt<PlayerRepository>()),
    )
    ..registerLazySingleton(() => PlayQueueUseCase(getIt<PlayerRepository>()))
    ..registerLazySingleton(
      () => PlaybackControlsUseCase(getIt<PlayerRepository>()),
    )
    ..registerLazySingleton(
      () => RestorePlaybackSessionUseCase(getIt<PlayerRepository>()),
    )
    ..registerLazySingleton(() => EditQueueUseCase(getIt<PlayerRepository>()))
    ..registerLazySingleton(
      () => WatchPlaybackProgressUseCase(getIt<PlayerRepository>()),
    );

  // App-wide: where playback is in the song (seek bar, times).
  getIt.registerLazySingleton<PlaybackProgressCubit>(
    () => PlaybackProgressCubit(getIt()),
    dispose: (cubit) => cubit.close(),
  );

  // App-wide: the mini player and the full player share this one state.
  getIt.registerLazySingleton<PlayerCubit>(
    () => PlayerCubit(
      watchNowPlaying: getIt(),
      playQueue: getIt(),
      controls: getIt(),
      restore: getIt(),
      editQueue: getIt(),
    ),
    dispose: (cubit) => cubit.close(),
  );
  // "Colours from the cover": the playing song's cover colour.
  getIt.registerLazySingleton<CoverAccentCubit>(
    () => CoverAccentCubit(
      nowPlaying: getIt<PlayerCubit>().stream,
      current: getIt<PlayerCubit>().state,
      preferences: getIt<UiPreferencesCubit>().stream,
      enabled: getIt<UiPreferencesCubit>().state.dynamicAccent,
      artwork: (songId) =>
          getIt<GetSongArtworkUseCase>()(SongArtworkParams(songId, size: 96)),
    ),
    dispose: (cubit) => cubit.close(),
  );
}
