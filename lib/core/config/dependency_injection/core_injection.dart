import 'package:melodix/core/preferences/app_language.dart';
import 'package:melodix/core/search/search_history.dart';
import 'package:get_it/get_it.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';
import 'package:melodix/core/service/app_icon_service.dart';
import 'package:melodix/core/preferences/library_filter.dart';
import 'package:melodix/core/database/playback_state_local_storage.dart';
import 'package:melodix/features/player/domain/usecases/playback_controls_usecase.dart';
import 'package:melodix/features/player/domain/usecases/watch_now_playing_usecase.dart';
import 'package:isar_community/isar.dart';
import 'package:melodix/core/database/favorites_local_storage.dart';
import 'package:melodix/core/database/isar_database.dart';
import 'package:melodix/core/database/music_local_storage.dart';
import 'package:melodix/core/database/playlist_local_storage.dart';
import 'package:melodix/core/database/recent_music_local_storage.dart';
import 'package:melodix/core/database/video_local_storage.dart';
import 'package:melodix/core/service/music_service.dart';
import 'package:melodix/core/service/permission_handling_service.dart';
import 'package:melodix/core/service/video_service.dart';
import 'package:melodix/core/service/playback_coordinator.dart';
import 'package:melodix/core/usecase/open_app_settings_usecase.dart';
import 'package:melodix/core/service/picture_in_picture_service.dart';
import 'package:melodix/core/service/app_lifecycle_service.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// App-wide pieces every feature uses: the database and its storages, the
/// platform services, app lifecycle, saved preferences, and the rule that
/// music and video never play at once.
Future<void> registerCore(GetIt getIt) async {
  /// What the library shows (Settings › Music filters).
  LibraryFilter libraryFilter() => getIt<LibraryFilterCubit>().state;

  getIt.registerLazySingleton<AppIconCubit>(
    () => AppIconCubit(AppIconService()),
    dispose: (cubit) => cubit.close(),
  );
  getIt.registerLazySingleton<LibraryFilterCubit>(
    LibraryFilterCubit.new,
    dispose: (cubit) => cubit.close(),
  );
  getIt.registerSingleton<Isar>(await IsarDatabase.open());

  getIt.registerLazySingleton<MusicLocalStorage>(
    () => MusicLocalStorageImpl(getIt<Isar>(), filter: libraryFilter),
  );
  getIt.registerLazySingleton<VideoLocalStorage>(
    () => VideoLocalStorageImpl(getIt<Isar>()),
  );
  getIt.registerLazySingleton<PlaylistLocalStorage>(
    () => PlaylistLocalStorageImpl(getIt<Isar>(), filter: libraryFilter),
  );
  getIt.registerLazySingleton<RecentMusicLocalStorage>(
    () => RecentMusicLocalStorageImpl(getIt<Isar>(), filter: libraryFilter),
  );
  getIt.registerLazySingleton<PlaybackStateLocalStorage>(
    () => PlaybackStateLocalStorageImpl(getIt<Isar>()),
  );
  getIt.registerLazySingleton<FavoritesLocalStorage>(
    () => FavoritesLocalStorageImpl(getIt<Isar>(), filter: libraryFilter),
  );

  // External
  getIt.registerLazySingleton<OnAudioQuery>(OnAudioQuery.new);

  // Services
  getIt.registerLazySingleton<PermissionHandlingService>(
    () => const PermissionHandlingServiceImpl(),
  );
  getIt.registerLazySingleton<MusicService>(
    () => MusicServiceImpl(
      audioQuery: getIt<OnAudioQuery>(),
      permissionService: getIt<PermissionHandlingService>(),
    ),
  );
  getIt.registerLazySingleton<PictureInPictureService>(
    PictureInPictureServiceImpl.new,
  );
  getIt.registerLazySingleton<VideoService>(
    () =>
        VideoServiceImpl(permissionService: getIt<PermissionHandlingService>()),
  );
  getIt.registerLazySingleton<AppLifecycleService>(AppLifecycleServiceImpl.new);
  getIt.registerLazySingleton(
    () => OpenAppSettingsUseCase(getIt<PermissionHandlingService>()),
  );
  // Settings' look and layout choices (and the video skip length), one
  // instance for the screens and the media controls. Created on first use,
  // after the saved state's storage is ready.
  // The search history (recent searches, what was opened from search),
  // saved across restarts. Created on first use, after the saved state's
  // storage is ready.
  // The app's language (Settings), saved across restarts.
  getIt.registerLazySingleton<AppLanguageCubit>(
    AppLanguageCubit.new,
    dispose: (cubit) => cubit.close(),
  );
  getIt.registerLazySingleton<SearchHistoryCubit>(
    SearchHistoryCubit.new,
    dispose: (cubit) => cubit.close(),
  );
  getIt.registerLazySingleton<UiPreferencesCubit>(
    UiPreferencesCubit.new,
    dispose: (cubit) => cubit.close(),
  );
  // No two soundtracks at once: a video pauses the music, and music
  // starting pauses the video.
  getIt.registerLazySingleton<PlaybackCoordinator>(
    () => PlaybackCoordinator(
      pauseMusic: () => getIt<PlaybackControlsUseCase>().pause(),
      musicPlaying: getIt<WatchNowPlayingUseCase>()().map(
        (music) => music.isPlaying,
      ),
    ),
  );
}
