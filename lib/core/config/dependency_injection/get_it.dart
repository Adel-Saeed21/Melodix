import 'package:get_it/get_it.dart';
import 'package:melodix/core/config/dependency_injection/core_injection.dart';
import 'package:melodix/features/music_library/data/datasources/music_local_storage.dart';
import 'package:melodix/core/preferences/library_filter.dart';
import 'package:melodix/features/lyrics/lyrics_injection.dart';
import 'package:melodix/features/music_library/music_library_injection.dart';
import 'package:melodix/features/player/data/audio_settings_binder.dart';
import 'package:melodix/features/player/player_injection.dart';
import 'package:melodix/features/stats/stats_injection.dart';
import 'package:melodix/features/subtitles/subtitles_injection.dart';
import 'package:melodix/features/video/video_injection.dart';

final getIt = GetIt.instance;

/// Registers everything the app needs: the shared core first (it opens
/// the database), then each feature's own module. Everything else is
/// created on first use, so the feature order doesn't matter.
Future<void> setupGetIt() async {
  await registerCore(getIt);
  registerMusicLibrary(getIt);
  registerPlayer(getIt);
  registerLyrics(getIt);
  registerVideo(getIt);
  registerSubtitles(getIt);
  registerStats(getIt);
}

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
