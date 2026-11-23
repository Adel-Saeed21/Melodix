import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:melodix/core/database/playback_state_local_storage.dart';
import 'package:melodix/features/music_library/data/mappers/song_mapper.dart';
import 'package:melodix/features/player/data/repositories/player_repository_impl.dart';
import 'package:melodix/features/player/domain/repositories/player_repository.dart';
import 'package:melodix/features/player/domain/usecases/play_queue_usecase.dart';
import 'package:melodix/features/player/domain/usecases/playback_controls_usecase.dart';
import 'package:melodix/features/player/domain/usecases/restore_playback_session_usecase.dart';
import 'package:melodix/features/player/domain/usecases/watch_now_playing_usecase.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';
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
import 'package:melodix/core/service/app_lifecycle_service.dart';
import 'package:melodix/features/music_library/data/repositories/music_library_repository_impl.dart';
import 'package:melodix/features/music_library/domain/repositories/music_library_repository.dart';
import 'package:melodix/features/music_library/domain/usecases/check_library_permission_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_album_songs_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_albums_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_artist_songs_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_artists_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_last_library_sync_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_song_artwork_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/open_library_settings_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/request_library_permission_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/sync_music_library_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_library_songs_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/toggle_song_favorite_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/set_song_hidden_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_hidden_songs_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_song_album_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_artist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_playlists_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/create_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/add_songs_to_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_playlists_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/get_playlist_songs_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/rename_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/delete_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/toggle_playlist_favorite_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/record_song_play_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/remove_song_from_playlist_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/reorder_playlist_songs_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/search_library_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/set_songs_favorite_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/set_songs_hidden_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/delete_songs_usecase.dart';
import 'package:melodix/features/music_library/presentation/logic/library_collections_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/library_search_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/playlists_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/presentation/logic/song_actions_cubit.dart';
import 'package:on_audio_query/on_audio_query.dart';

final getIt = GetIt.instance;

Future<void> setupGetIt() async {
  await _setupDatabase();
  _setupMedia();
  _setupMusicLibrary();
  _setupPlayer();
}

Future<void> _setupDatabase() async {
  getIt.registerSingleton<Isar>(await IsarDatabase.open());

  getIt.registerLazySingleton<MusicLocalStorage>(
    () => MusicLocalStorageImpl(getIt<Isar>()),
  );
  getIt.registerLazySingleton<VideoLocalStorage>(
    () => VideoLocalStorageImpl(getIt<Isar>()),
  );
  getIt.registerLazySingleton<PlaylistLocalStorage>(
    () => PlaylistLocalStorageImpl(getIt<Isar>()),
  );
  getIt.registerLazySingleton<RecentMusicLocalStorage>(
    () => RecentMusicLocalStorageImpl(getIt<Isar>()),
  );
  getIt.registerLazySingleton<PlaybackStateLocalStorage>(
    () => PlaybackStateLocalStorageImpl(getIt<Isar>()),
  );
  getIt.registerLazySingleton<FavoritesLocalStorage>(
    () => FavoritesLocalStorageImpl(getIt<Isar>()),
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
  getIt.registerLazySingleton<VideoService>(
    () =>
        VideoServiceImpl(permissionService: getIt<PermissionHandlingService>()),
  );
}

void _setupMusicLibrary() {
  getIt.registerLazySingleton<AppLifecycleService>(AppLifecycleServiceImpl.new);

  // Repository
  getIt.registerLazySingleton<MusicLibraryRepository>(
    () => MusicLibraryRepositoryImpl(
      musicService: getIt<MusicService>(),
      storage: getIt<MusicLocalStorage>(),
      permissionService: getIt<PermissionHandlingService>(),
      playlistStorage: getIt<PlaylistLocalStorage>(),
    ),
  );

  // Use cases
  getIt
    ..registerLazySingleton(
      () => CheckLibraryPermissionUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => RequestLibraryPermissionUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => SyncMusicLibraryUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => GetLastLibrarySyncUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => WatchLibrarySongsUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => GetAlbumsUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => GetArtistsUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => GetAlbumSongsUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => GetArtistSongsUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => GetSongArtworkUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => OpenLibrarySettingsUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => ToggleSongFavoriteUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => SetSongHiddenUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => WatchHiddenSongsUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => GetSongAlbumUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => GetArtistUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => GetPlaylistsUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => CreatePlaylistUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => AddSongsToPlaylistUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => WatchPlaylistsUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => GetPlaylistSongsUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => RenamePlaylistUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => DeletePlaylistUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => TogglePlaylistFavoriteUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => RemoveSongFromPlaylistUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => ReorderPlaylistSongsUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => SearchLibraryUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => RecordSongPlayUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => SetSongsHiddenUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => SetSongsFavoriteUseCase(getIt<MusicLibraryRepository>()),
    )
    ..registerLazySingleton(
      () => DeleteSongsUseCase(getIt<MusicLibraryRepository>()),
    );

  // App-wide: one library state shared by every screen.
  getIt.registerLazySingleton<MusicLibraryBloc>(
    () => MusicLibraryBloc(
      checkPermission: getIt(),
      requestPermission: getIt(),
      syncLibrary: getIt(),
      getLastSync: getIt(),
      watchSongs: getIt(),
      lifecycle: getIt(),
      openSettings: getIt(),
    ),
    dispose: (bloc) => bloc.close(),
  );

  // Per screen: albums and artists for the Music home tabs.
  getIt.registerFactory<LibraryCollectionsCubit>(
    () => LibraryCollectionsCubit(getAlbums: getIt(), getArtists: getIt()),
  );
  getIt.registerFactory<SongActionsCubit>(
    () => SongActionsCubit(
      toggleFavorite: getIt(),
      setHidden: getIt(),
      getPlaylists: getIt(),
      createPlaylist: getIt(),
      addToPlaylist: getIt(),
      getAlbum: getIt(),
      getArtist: getIt(),
      removeFromPlaylist: getIt(),
      setSongsHidden: getIt(),
      setSongsFavorite: getIt(),
      deleteSongs: getIt(),
    ),
  );
  getIt.registerFactory<LibrarySearchCubit>(
    () => LibrarySearchCubit(search: getIt()),
  );
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

void _setupPlayer() {
  // The app's only audio player instance.
  getIt.registerLazySingleton<AudioPlayer>(AudioPlayer.new);

  getIt.registerLazySingleton<PlayerRepository>(
    () => PlayerRepositoryImpl(
      player: getIt<AudioPlayer>(),
      sessionStorage: getIt<PlaybackStateLocalStorage>(),
      musicStorage: getIt<MusicLocalStorage>(),
      mapper: SongMapper(isAndroid: Platform.isAndroid),
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
    );

  // App-wide: the mini player and the full player share this one state.
  getIt.registerLazySingleton<PlayerCubit>(
    () => PlayerCubit(
      watchNowPlaying: getIt(),
      playQueue: getIt(),
      controls: getIt(),
      restore: getIt(),
    ),
    dispose: (cubit) => cubit.close(),
  );
}
