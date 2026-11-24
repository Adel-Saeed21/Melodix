import 'dart:developer' as developer;
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:melodix/core/config/theme/app_colors.dart';
import 'package:melodix/features/music_library/domain/repositories/artwork_repository.dart';
import 'package:melodix/features/music_library/domain/usecases/toggle_song_favorite_usecase.dart';
import 'package:melodix/features/music_library/domain/usecases/watch_song_favorite_usecase.dart';
import 'package:melodix/features/player/data/background/fallback_cover.dart';
import 'package:melodix/features/player/data/background/melodix_audio_handler.dart';
import 'package:melodix/features/player/data/background/now_playing_artwork_files.dart';
import 'package:melodix/features/player/domain/repositories/player_repository.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Starts the media session: music keeps playing with the app in the
/// background or the screen off, with controls in the notification, on the
/// lock screen and on headset / Bluetooth / car buttons.
///
/// Call once at startup, after dependencies are set up. If it fails (e.g.
/// an unsupported platform) the app still works; playback then simply
/// stops when the app is closed.
Future<void> startBackgroundPlayback({
  required PlayerRepository player,
  required ArtworkRepository artwork,
  required WatchSongFavoriteUseCase watchFavorite,
  required ToggleSongFavoriteUseCase toggleFavorite,
}) async {
  try {
    await AudioService.init(
      builder: () => MelodixAudioHandler(
        player,
        artwork: NowPlayingArtworkFiles(
          artwork: artwork,
          directory: () async => Directory(
            p.join((await getTemporaryDirectory()).path, 'now_playing_art'),
          ),
          fallbackCover: renderFallbackCover,
        ),
        watchFavorite: watchFavorite,
        toggleFavorite: toggleFavorite,
      ),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.melodix.playback',
        androidNotificationChannelName: 'Playback',
        androidNotificationChannelDescription:
            'The song playing, with playback controls',
        // The app's music note in the status bar and the notification header,
        // tinted with the app's green where Android supports it (12 and
        // below; Android 13+ colours the player from the cover instead).
        androidNotificationIcon: 'drawable/ic_stat_melodix',
        notificationColor: AppColors.primaryColor,
        // Can't be swiped away while playing; can once paused (and then
        // the app may be closed by the system, like any paused player).
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  } catch (error, stack) {
    developer.log(
      'Background playback unavailable',
      name: 'melodix.player',
      error: error,
      stackTrace: stack,
    );
  }
}
