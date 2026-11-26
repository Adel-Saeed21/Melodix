import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_event.dart';
import 'package:melodix/features/music_library/domain/repositories/artwork_repository.dart';
import 'package:melodix/features/music_library/domain/usecases/toggle_song_favorite_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_song_favorite_usecase.dart';
import 'package:melodix/features/player/data/background/background_playback.dart';
import 'package:melodix/features/player/domain/repositories/player_repository.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';
import 'package:melodix/features/video/presentation/playback/video_media_session.dart';
import 'package:melodix/melodix_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Saved settings first: the library and player read them from the start.
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory(
            (await getApplicationDocumentsDirectory()).path,
          ),
  );

  await setupGetIt();
  // Loads saved songs and syncs in the background if access is granted.
  getIt<MusicLibraryBloc>().add(const MusicLibraryStarted());
  // Last song, position and queue, ready to resume (paused).
  unawaited(getIt<PlayerCubit>().restore());
  // Music keeps playing in the background, with notification and
  // lock-screen controls.
  unawaited(
    startBackgroundPlayback(
      player: getIt<PlayerRepository>(),
      artwork: getIt<ArtworkRepository>(),
      watchFavorite: getIt<WatchSongFavoriteUseCase>(),
      toggleFavorite: getIt<ToggleSongFavoriteUseCase>(),
      // A playing video takes over the notification and headset buttons.
      guest: getIt<VideoMediaSession>(),
    ),
  );

  // Saved speed, skip silence, equalizer and music filters, applied.
  startSettingsBindings();

  runApp(const MelodixApp());
}
