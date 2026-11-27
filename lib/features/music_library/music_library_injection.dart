import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:melodix/features/music_library/data/mappers/song_mapper.dart';
import 'package:melodix/core/database/music_local_storage.dart';
import 'package:melodix/core/database/playlist_local_storage.dart';
import 'package:melodix/core/database/recent_music_local_storage.dart';
import 'package:melodix/core/service/music_service.dart';
import 'package:melodix/core/service/permission_handling_service.dart';
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

/// The music library: sync with the device, songs, playlists, recently
/// played, artwork, and the cubits the Music screens use.
void registerMusicLibrary(GetIt getIt) {
  getIt.registerLazySingleton<AudioLibraryDeltaSource>(
    () => const MediaStoreDeltaSource(),
  );

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
