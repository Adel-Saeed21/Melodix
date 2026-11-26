import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:melodix/features/subtitles/data/datasources/opensubtitles/opensubtitles_api.dart';
import 'package:melodix/features/subtitles/data/datasources/opensubtitles/opensubtitles_config.dart';
import 'package:melodix/features/subtitles/data/datasources/opensubtitles/opensubtitles_remote_data_source.dart';
import 'package:melodix/features/subtitles/data/datasources/subtitle_device_source.dart';
import 'package:melodix/features/subtitles/data/datasources/subtitle_local_storage.dart';
import 'package:melodix/features/subtitles/data/repositories/subtitle_repository_impl.dart';
import 'package:melodix/features/subtitles/domain/repositories/subtitle_repository.dart';
import 'package:melodix/features/subtitles/domain/usecases/subtitle_usecases.dart';
import 'package:melodix/features/subtitles/presentation/logic/subtitles_cubit.dart';

import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';
import 'package:melodix/features/video/presentation/playback/video_media_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:melodix/core/service/app_icon_service.dart';
import 'package:melodix/core/preferences/library_filter.dart';
import 'package:melodix/features/lyrics/data/lrclib_client.dart';
import 'package:melodix/features/lyrics/data/lyrics_repository_impl.dart';
import 'package:melodix/features/lyrics/domain/repositories/lyrics_repository.dart';
import 'package:melodix/features/player/data/audio_settings_binder.dart';
import 'package:melodix/features/player/data/equalizer/android_equalizer_engine.dart';
import 'package:melodix/features/player/domain/repositories/equalizer_engine.dart';
import 'package:melodix/features/player/presentation/logic/audio_settings_cubit.dart';
import 'package:melodix/features/player/presentation/logic/sleep_timer_cubit.dart';
import 'package:melodix/features/player/presentation/logic/cover_accent_cubit.dart';
import 'package:melodix/core/database/playback_state_local_storage.dart';
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
import 'package:melodix/features/video/presentation/playback/video_progress_tracker.dart';
import 'package:melodix/core/usecase/open_app_settings_usecase.dart';
import 'package:melodix/core/service/picture_in_picture_service.dart';
import 'package:melodix/core/service/app_lifecycle_service.dart';
import 'package:melodix/core/service/audio_library_delta_source.dart';
import 'package:melodix/features/music_library/data/repositories/artwork_repository_impl.dart';
import 'package:melodix/features/music_library/data/repositories/library_permission_repository_impl.dart';
import 'package:melodix/features/music_library/data/repositories/library_sync_repository_impl.dart';
import 'package:melodix/features/music_library/data/repositories/playlist_repository_impl.dart';
import 'package:melodix/features/music_library/data/repositories/song_repository_impl.dart';
import 'package:melodix/features/music_library/data/sync/full_library_scan.dart';
import 'package:melodix/features/music_library/data/sync/incremental_library_scan.dart';
import 'package:melodix/features/music_library/domain/repositories/artwork_repository.dart';
import 'package:melodix/features/music_library/domain/repositories/library_permission_repository.dart';
import 'package:melodix/features/music_library/domain/repositories/library_sync_repository.dart';
import 'package:melodix/features/music_library/domain/repositories/playlist_repository.dart';
import 'package:melodix/features/music_library/domain/repositories/song_repository.dart';
import 'package:melodix/features/music_library/domain/usecases/build_library_catalog_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/check_library_permission_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_last_library_sync_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_song_artwork_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/open_library_settings_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/request_library_permission_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/sync_music_library_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_library_songs_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/toggle_song_favorite_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_song_favorite_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_library_sync_stage_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_recently_played_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/clear_recently_played_usecase.dart';
import 'package:melodix/features/music_library/domain/repositories/recently_played_repository.dart';
import 'package:melodix/features/music_library/data/repositories/recently_played_repository_impl.dart';
import 'package:melodix/features/music_library/domain/usecases/get_playlists_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/create_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/add_songs_to_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_playlists_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_playlist_songs_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/rename_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/delete_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/toggle_playlist_favorite_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/remove_song_from_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/reorder_playlist_songs_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/set_songs_favorite_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/delete_songs_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/library_collections_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/library_search_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/playlists_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/presentation/logic/song_actions_cubit.dart';
import 'package:on_audio_query/on_audio_query.dart';
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

final getIt = GetIt.instance;

/// What the library shows (Settings › Music filters).
LibraryFilter _libraryFilter() => getIt<LibraryFilterCubit>().state;

/// Starts what keeps saved settings applied: speed, skip silence and the
/// equalizer on the player; the music filters on the library. Call once
/// `HydratedBloc.storage` is set.
void startSettingsBindings() {
  getIt<AudioSettingsBinder>();
  // A filter change shows the library again, filtered anew.
  getIt<LibraryFilterCubit>().stream.listen(
    (_) => getIt<MusicLocalStorage>().reloadLibrary(),
  );
}

Future<void> setupGetIt() async {
  await _setupDatabase();
  _setupMedia();
  _setupMusicLibrary();
  _setupVideo();
  _setupPlayer();
}

Future<void> _setupDatabase() async {
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
    () => MusicLocalStorageImpl(getIt<Isar>(), filter: _libraryFilter),
  );
  getIt.registerLazySingleton<VideoLocalStorage>(
    () => VideoLocalStorageImpl(getIt<Isar>()),
  );
  getIt.registerLazySingleton<PlaylistLocalStorage>(
    () => PlaylistLocalStorageImpl(getIt<Isar>(), filter: _libraryFilter),
  );
  getIt.registerLazySingleton<RecentMusicLocalStorage>(
    () => RecentMusicLocalStorageImpl(getIt<Isar>(), filter: _libraryFilter),
  );
  getIt.registerLazySingleton<PlaybackStateLocalStorage>(
    () => PlaybackStateLocalStorageImpl(getIt<Isar>()),
  );
  getIt.registerLazySingleton<FavoritesLocalStorage>(
    () => FavoritesLocalStorageImpl(getIt<Isar>(), filter: _libraryFilter),
  );
}

void _setupMedia() {
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
}

void _setupMusicLibrary() {
  getIt.registerLazySingleton<AudioLibraryDeltaSource>(
    () => const MediaStoreDeltaSource(),
  );
  getIt.registerLazySingleton<AppLifecycleService>(AppLifecycleServiceImpl.new);

  getIt.registerLazySingleton<SongMapper>(
    () => SongMapper(isAndroid: Platform.isAndroid),
  );

  // Sync strategies
  getIt.registerLazySingleton<FullLibraryScan>(
    () => FullLibraryScan(
      musicService: getIt<MusicService>(),
      deltaSource: getIt<AudioLibraryDeltaSource>(),
      storage: getIt<MusicLocalStorage>(),
    ),
  );
  getIt.registerLazySingleton<IncrementalLibraryScan>(
    () => IncrementalLibraryScan(
      deltaSource: getIt<AudioLibraryDeltaSource>(),
      storage: getIt<MusicLocalStorage>(),
    ),
  );

  // Repositories (one per concern)
  getIt.registerLazySingleton<LibraryPermissionRepository>(
    () => LibraryPermissionRepositoryImpl(getIt<PermissionHandlingService>()),
  );
  getIt.registerLazySingleton<LibrarySyncRepository>(
    () => LibrarySyncRepositoryImpl(
      permissionService: getIt<PermissionHandlingService>(),
      deltaSource: getIt<AudioLibraryDeltaSource>(),
      storage: getIt<MusicLocalStorage>(),
      fullScan: getIt<FullLibraryScan>(),
      incrementalScan: getIt<IncrementalLibraryScan>(),
    ),
  );
  getIt.registerLazySingleton<SongRepository>(
    () => SongRepositoryImpl(
      storage: getIt<MusicLocalStorage>(),
      musicService: getIt<MusicService>(),
      mapper: getIt<SongMapper>(),
    ),
  );
  getIt.registerLazySingleton<PlaylistRepository>(
    () => PlaylistRepositoryImpl(
      storage: getIt<PlaylistLocalStorage>(),
      mapper: getIt<SongMapper>(),
    ),
  );
  getIt.registerLazySingleton<RecentlyPlayedRepository>(
    () => RecentlyPlayedRepositoryImpl(
      storage: getIt<RecentMusicLocalStorage>(),
      mapper: getIt<SongMapper>(),
    ),
  );
  getIt.registerLazySingleton<ArtworkRepository>(
    () => ArtworkRepositoryImpl(getIt<MusicService>()),
  );

  // Use cases
  getIt
    ..registerLazySingleton(
      () => CheckLibraryPermissionUseCase(getIt<LibraryPermissionRepository>()),
    )
    ..registerLazySingleton(
      () =>
          RequestLibraryPermissionUseCase(getIt<LibraryPermissionRepository>()),
    )
    ..registerLazySingleton(
      () => SyncMusicLibraryUseCase(getIt<LibrarySyncRepository>()),
    )
    ..registerLazySingleton(
      () => GetLastLibrarySyncUseCase(getIt<LibrarySyncRepository>()),
    )
    ..registerLazySingleton(
      () => WatchLibrarySyncStageUseCase(getIt<LibrarySyncRepository>()),
    )
    ..registerLazySingleton(
      () => WatchLibrarySongsUseCase(getIt<SongRepository>()),
    )
    ..registerLazySingleton(() => const BuildLibraryCatalogUseCase())
    ..registerLazySingleton(
      () => GetSongArtworkUseCase(getIt<ArtworkRepository>()),
    )
    ..registerLazySingleton(
      () => OpenLibrarySettingsUseCase(getIt<LibraryPermissionRepository>()),
    )
    ..registerLazySingleton(
      () => ToggleSongFavoriteUseCase(getIt<SongRepository>()),
    )
    ..registerLazySingleton(
      () => WatchSongFavoriteUseCase(getIt<SongRepository>()),
    )
    ..registerLazySingleton(
      () => WatchRecentlyPlayedUseCase(getIt<RecentlyPlayedRepository>()),
    )
    ..registerLazySingleton(
      () => ClearRecentlyPlayedUseCase(getIt<RecentlyPlayedRepository>()),
    )
    ..registerLazySingleton(
      () => GetPlaylistsUseCase(getIt<PlaylistRepository>()),
    )
    ..registerLazySingleton(
      () => CreatePlaylistUseCase(getIt<PlaylistRepository>()),
    )
    ..registerLazySingleton(
      () => AddSongsToPlaylistUseCase(getIt<PlaylistRepository>()),
    )
    ..registerLazySingleton(
      () => WatchPlaylistsUseCase(getIt<PlaylistRepository>()),
    )
    ..registerLazySingleton(
      () => GetPlaylistSongsUseCase(getIt<PlaylistRepository>()),
    )
    ..registerLazySingleton(
      () => RenamePlaylistUseCase(getIt<PlaylistRepository>()),
    )
    ..registerLazySingleton(
      () => DeletePlaylistUseCase(getIt<PlaylistRepository>()),
    )
    ..registerLazySingleton(
      () => TogglePlaylistFavoriteUseCase(getIt<PlaylistRepository>()),
    )
    ..registerLazySingleton(
      () => RemoveSongFromPlaylistUseCase(getIt<PlaylistRepository>()),
    )
    ..registerLazySingleton(
      () => ReorderPlaylistSongsUseCase(getIt<PlaylistRepository>()),
    )
    ..registerLazySingleton(
      () => SetSongsFavoriteUseCase(getIt<SongRepository>()),
    )
    ..registerLazySingleton(() => DeleteSongsUseCase(getIt<SongRepository>()));

  // App-wide: one library state shared by every screen.
  getIt.registerLazySingleton<MusicLibraryBloc>(
    () => MusicLibraryBloc(
      checkPermission: getIt(),
      requestPermission: getIt(),
      syncLibrary: getIt(),
      getLastSync: getIt(),
      watchSongs: getIt(),
      watchSyncStage: getIt(),
      lifecycle: getIt(),
      openSettings: getIt(),
    ),
    dispose: (bloc) => bloc.close(),
  );

  // Per screen: albums and artists for the Music home tabs.
  getIt.registerFactory<LibraryCollectionsCubit>(
    () => LibraryCollectionsCubit(buildCatalog: getIt()),
  );
  getIt.registerFactory<SongActionsCubit>(
    () => SongActionsCubit(
      toggleFavorite: getIt(),
      watchFavorite: getIt(),
      getPlaylists: getIt(),
      createPlaylist: getIt(),
      addToPlaylist: getIt(),
      removeFromPlaylist: getIt(),
      setSongsFavorite: getIt(),
      deleteSongs: getIt(),
    ),
  );
  getIt.registerFactory<LibrarySearchCubit>(LibrarySearchCubit.new);
  getIt.registerFactory<PlaylistsCubit>(
    () => PlaylistsCubit(
      watchPlaylists: getIt(),
      createPlaylist: getIt(),
      renamePlaylist: getIt(),
      deletePlaylist: getIt(),
      toggleFavorite: getIt(),
    ),
  );
}

void _setupVideo() {
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
  getIt.registerLazySingleton(
    () => OpenAppSettingsUseCase(getIt<PermissionHandlingService>()),
  );
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
  // Settings' look and layout choices (and the video skip length), one
  // instance for the screens and the media controls. Created on first use,
  // after the saved state's storage is ready.
  getIt.registerLazySingleton<UiPreferencesCubit>(
    UiPreferencesCubit.new,
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
    ),
    dispose: (session) => session.dispose(),
  );
  _setupSubtitles();
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

void _setupPlayer() {
  // The phone's equalizer (Android), in the player's audio pipeline.
  final androidEqualizer = defaultTargetPlatform == TargetPlatform.android
      ? AndroidEqualizer()
      : null;
  getIt.registerLazySingleton<EqualizerEngine>(
    () => androidEqualizer == null
        ? const UnsupportedEqualizerEngine()
        : AndroidEqualizerEngine(androidEqualizer),
  );
  // The app's only audio player instance.
  getIt.registerLazySingleton<AudioPlayer>(
    () => AudioPlayer(
      audioPipeline: AudioPipeline(androidAudioEffects: [?androidEqualizer]),
    ),
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
  // Lyrics: saved, beside the song, in its tags; LRCLIB when asked.
  getIt.registerLazySingleton<LyricsRepository>(
    () => LyricsRepositoryImpl(
      savedDirectory: getApplicationDocumentsDirectory,
      online: LrclibClient(),
    ),
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

/// Subtitles: files next to the video, imported, or downloaded from
/// OpenSubtitles and kept, so all of them work offline.
void _setupSubtitles() {
  final config = OpenSubtitlesConfig.fromEnvironment();
  getIt
    ..registerLazySingleton<SubtitleRepository>(
      () => SubtitleRepositoryImpl(
        storage: SubtitleLocalStorage(
          root: () async => Directory(
            p.join((await getApplicationSupportDirectory()).path, 'subtitles'),
          ),
        ),
        device: SubtitleDeviceSourceImpl(),
        remote: OpenSubtitlesRemoteDataSource(
          config: config,
          api: OpenSubtitlesApi(
            OpenSubtitlesRemoteDataSource.createDio(config),
          ),
          files: OpenSubtitlesRemoteDataSource.createFileDio(config),
        ),
        playbackUri: (id) => getIt<GetVideoPlaybackUriUseCase>()(id),
      ),
    )
    ..registerLazySingleton(() => GetSubtitleTracksUseCase(getIt()))
    ..registerLazySingleton(() => LoadSubtitleUseCase(getIt()))
    ..registerLazySingleton(() => SubtitleSelectionUseCase(getIt()))
    ..registerLazySingleton(() => ImportSubtitleUseCase(getIt()))
    ..registerLazySingleton(() => SearchOnlineSubtitlesUseCase(getIt()))
    ..registerLazySingleton(() => DownloadSubtitleUseCase(getIt()))
    ..registerLazySingleton<SubtitlesCubit>(() {
      final session = getIt<VideoPlayerCubit>();
      String? videoOf(VideoPlayerState s) => s.isActive ? s.video.id : null;
      return SubtitlesCubit(
        getTracks: getIt(),
        load: getIt(),
        selection: getIt(),
        import: getIt(),
        currentVideo: session.stream.map(videoOf).distinct(),
        initialVideo: videoOf(session.state),
      );
    }, dispose: (cubit) => cubit.close());
}
