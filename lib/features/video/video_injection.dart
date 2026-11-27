import 'package:melodix/core/preferences/app_language.dart';
import 'package:get_it/get_it.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';
import 'package:melodix/features/video/presentation/playback/video_media_session.dart';
import 'package:melodix/features/video/data/datasources/video_local_storage.dart';
import 'package:melodix/features/video/data/datasources/video_service.dart';
import 'package:melodix/core/service/playback_coordinator.dart';
import 'package:melodix/features/video/presentation/playback/video_progress_tracker.dart';
import 'package:melodix/core/service/app_lifecycle_service.dart';
import 'package:melodix/features/video/data/repositories/video_media_repository_impl.dart';
import 'package:melodix/features/video/data/repositories/video_permission_repository_impl.dart';
import 'package:melodix/features/video/data/repositories/video_progress_repository_impl.dart';
import 'package:melodix/features/video/data/repositories/video_repository_impl.dart';
import 'package:melodix/features/video/data/repositories/video_sync_repository_impl.dart';
import 'package:melodix/features/video/domain/repositories/video_media_repository.dart';
import 'package:melodix/features/video/domain/repositories/video_permission_repository.dart';
import 'package:melodix/features/video/domain/repositories/video_progress_repository.dart';
import 'package:melodix/features/video/domain/repositories/video_repository.dart';
import 'package:melodix/features/video/domain/repositories/video_sync_repository.dart';
import 'package:melodix/features/video/domain/usecases/get_video_playback_uri_usecase.dart';
import 'package:melodix/features/video/domain/usecases/get_video_thumbnail_usecase.dart';
import 'package:melodix/features/video/domain/usecases/sync_video_library_usecase.dart';
import 'package:melodix/features/video/domain/usecases/toggle_video_favorite_usecase.dart';
import 'package:melodix/features/video/domain/usecases/watch_favorite_videos_usecase.dart';
import 'package:melodix/features/video/domain/usecases/watch_videos_usecase.dart';
import 'package:melodix/features/video/presentation/logic/favorite_videos_cubit.dart';
import 'package:melodix/features/video/domain/usecases/video_permission_usecases.dart';
import 'package:melodix/features/video/domain/usecases/video_progress_usecases.dart';
import 'package:melodix/features/video/domain/usecases/video_bulk_usecases.dart';
import 'package:melodix/features/video/presentation/logic/video_library_cubit.dart';
import 'package:melodix/features/video/presentation/search/video_search_source.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';

/// Videos: the library, the player session shared by the full player and
/// the small window, its media controls, search and favourites.
void registerVideo(GetIt getIt) {
  getIt
    ..registerLazySingleton<VideoRepository>(
      () => VideoRepositoryImpl(
        storage: getIt<VideoLocalStorage>(),
        service: getIt<VideoService>(),
      ),
    )
    ..registerLazySingleton<VideoSyncRepository>(
      () => VideoSyncRepositoryImpl(
        service: getIt<VideoService>(),
        storage: getIt<VideoLocalStorage>(),
      ),
    )
    ..registerLazySingleton<VideoPermissionRepository>(
      () => VideoPermissionRepositoryImpl(getIt<VideoService>()),
    )
    ..registerLazySingleton<VideoProgressRepository>(
      () => VideoProgressRepositoryImpl(getIt<VideoLocalStorage>()),
    )
    ..registerLazySingleton<VideoMediaRepository>(
      () => VideoMediaRepositoryImpl(getIt<VideoService>()),
    );
  getIt
    ..registerLazySingleton(() => WatchVideosUseCase(getIt()))
    ..registerLazySingleton(() => WatchFavoriteVideosUseCase(getIt()))
    ..registerLazySingleton(() => SyncVideoLibraryUseCase(getIt()))
    ..registerLazySingleton(() => ToggleVideoFavoriteUseCase(getIt()))
    ..registerLazySingleton(() => GetVideoThumbnailUseCase(getIt()))
    ..registerLazySingleton(() => GetVideoPlaybackUriUseCase(getIt()))
    ..registerLazySingleton(() => SetVideosFavoriteUseCase(getIt()))
    ..registerLazySingleton(() => DeleteVideosUseCase(getIt()))
    ..registerLazySingleton(() => WatchVideoProgressUseCase(getIt()))
    ..registerLazySingleton(() => GetVideoProgressUseCase(getIt()))
    ..registerLazySingleton(() => RecordVideoPlayUseCase(getIt()))
    ..registerLazySingleton(() => SaveVideoPositionUseCase(getIt()))
    ..registerLazySingleton(() => CheckVideoPermissionUseCase(getIt()))
    ..registerLazySingleton(() => RequestVideoPermissionUseCase(getIt()));
  getIt.registerFactory<VideoLibraryCubit>(
    () => VideoLibraryCubit(
      watchVideos: getIt(),
      sync: getIt(),
      checkPermission: getIt(),
      requestPermission: getIt(),
      openSettings: getIt(),
      watchProgress: getIt(),
      appResumed: getIt<AppLifecycleService>().onResumed,
      // Automatic syncs wait while a video is open.
      isPlaybackActive: () => getIt<VideoPlayerCubit>().state.isActive,
      playbackActive: getIt<VideoPlayerCubit>().stream
          .map((session) => session.isActive)
          .distinct(),
    ),
  );
  // App-wide: the full player and the small window share this session.
  getIt.registerLazySingleton<VideoPlayerCubit>(
    () => VideoPlayerCubit(
      playbackUri: getIt(),
      progress: VideoProgressTracker(
        progress: getIt(),
        savePosition: getIt(),
        recordPlay: getIt(),
      ),
      coordinator: getIt(),
    ),
    dispose: (cubit) => cubit.close(),
  );
  // While a video plays, the notification, lock screen and headset buttons
  // control it instead of the music.
  getIt.registerLazySingleton<VideoMediaSession>(
    () => VideoMediaSession(
      session: getIt(),
      musicStarted: getIt<PlaybackCoordinator>().musicStarted,
      seekStep: () => getIt<UiPreferencesCubit>().state.videoSeekStep,
      thumbnail: (id) async => getIt<GetVideoThumbnailUseCase>()(id, size: 512),
      strings: () => getIt<AppLanguageCubit>().strings,
    ),
    dispose: (session) => session.dispose(),
  );
  // Lets the library search find videos too.
  getIt.registerLazySingleton<VideoSearchSource>(
    () => VideoSearchSource(getIt()),
    dispose: (source) => source.dispose(),
  );
  // App-wide: the favourite videos, and the one way to (un)favourite.
  getIt.registerLazySingleton<FavoriteVideosCubit>(
    () => FavoriteVideosCubit(
      watchFavorites: getIt(),
      toggleFavorite: getIt(),
      setFavorite: getIt(),
    ),
    dispose: (cubit) => cubit.close(),
  );
}
