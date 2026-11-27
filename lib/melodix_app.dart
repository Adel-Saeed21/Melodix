import 'package:melodix/core/l10n/language_switcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/preferences/app_language.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/features/subtitles/presentation/logic/subtitles_cubit.dart';
import 'package:melodix/core/widgets/app_screen_util_init.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';
import 'package:melodix/core/preferences/library_filter.dart';
import 'package:melodix/core/service/app_icon_service.dart';
import 'package:melodix/core/config/routing/app_route.dart';
import 'package:melodix/core/config/theme/app_theme.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/config/theme/theme_cubit/theme_cubit.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/player/presentation/logic/playback_progress_cubit.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';
import 'package:melodix/core/config/routing/routes.dart';
import 'package:melodix/core/service/picture_in_picture_service.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:melodix/features/video/presentation/logic/favorite_videos_cubit.dart';
import 'package:melodix/features/video/domain/usecases/video_bulk_usecases.dart';
import 'package:melodix/features/video/presentation/widgets/mini/video_session_host.dart';
import 'package:melodix/features/video/presentation/widgets/mini/mini_video_window.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/presentation/logic/audio_settings_cubit.dart';
import 'package:melodix/features/player/presentation/logic/cover_accent_cubit.dart';
import 'package:melodix/features/player/presentation/logic/sleep_timer_cubit.dart';

class MelodixApp extends StatelessWidget {
  const MelodixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        // Layout choices from Settings (mini player, selection bar).
        // The same instance the media controls read the skip length from.
        BlocProvider<UiPreferencesCubit>.value(
          value: getIt<UiPreferencesCubit>(),
        ),
        // App-wide player state (mini player, full player, song taps).
        BlocProvider<PlayerCubit>.value(value: getIt<PlayerCubit>()),
        // Music filters (Settings) and the home-screen icon.
        BlocProvider<LibraryFilterCubit>.value(
          value: getIt<LibraryFilterCubit>(),
        ),
        // Lazy (created on first use, unlike the `.value` ones): it asks the
        // phone for the current icon, which only Settings shows.
        BlocProvider<AppIconCubit>(create: (_) => getIt<AppIconCubit>()),
        // Speed, skip silence, equalizer; the sleep timer.
        BlocProvider<AudioSettingsCubit>.value(
          value: getIt<AudioSettingsCubit>(),
        ),
        BlocProvider<SleepTimerCubit>.value(value: getIt<SleepTimerCubit>()),
        // The playing song's cover colour (when the accent follows it).
        BlocProvider<CoverAccentCubit>.value(value: getIt<CoverAccentCubit>()),
        BlocProvider<PlaybackProgressCubit>.value(
          value: getIt<PlaybackProgressCubit>(),
        ),
        // App-wide library: album / artist pages show its songs live.
        BlocProvider<MusicLibraryBloc>.value(value: getIt<MusicLibraryBloc>()),
        // App-wide video session: the full player and the small window.
        BlocProvider<VideoPlayerCubit>.value(value: getIt<VideoPlayerCubit>()),
        // The open video's subtitles (follows the video session).
        // Lazy: made when a video first opens (it picks up the open one).
        BlocProvider<SubtitlesCubit>(create: (_) => getIt<SubtitlesCubit>()),
        // Deleting videos from the phone (a row's ⋮ anywhere, a selection).
        RepositoryProvider<DeleteVideosUseCase>.value(
          value: getIt<DeleteVideosUseCase>(),
        ),
        // App-wide favourite videos (♥ in the Video tab, Favourites, player).
        // Lazy: its database query waits for a screen that shows videos.
        BlocProvider<FavoriteVideosCubit>(
          create: (_) => getIt<FavoriteVideosCubit>(),
        ),
        // The app's language (Settings), or the phone's.
        BlocProvider<AppLanguageCubit>.value(value: getIt<AppLanguageCubit>()),
      ],
      child: AppScreenUtilInit(
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, mode) {
            return BlocBuilder<UiPreferencesCubit, UiPreferences>(
              builder: (context, preferences) => UiPreferencesScope(
                preferences: preferences,
                child: BlocBuilder<CoverAccentCubit, Color?>(
                  builder: (context, cover) => MaterialApp.router(
                    debugShowCheckedModeBanner: false,
                    // In the accent the user picked (Settings), or the
                    // playing song's cover colour (MaterialApp fades between
                    // themes, so a new song's colour blends in).
                    theme: cover == null
                        ? AppTheme.light(preferences.accent)
                        : AppTheme.forColor(cover, Brightness.light),
                    darkTheme: cover == null
                        ? AppTheme.dark(preferences.accent)
                        : AppTheme.forColor(cover, Brightness.dark),
                    themeMode: mode,
                    // English or Arabic (right to left), from
                    // easy_localization (see AppTranslations, LanguageSwitcher).
                    locale: context.locale,
                    supportedLocales: context.supportedLocales,
                    localizationsDelegates: appLocalizationsDelegates(context),
                    routerConfig: AppRoute.router,
                    // Over every page: the language switch's fade and the
                    // small video window.
                    builder: (context, child) => LanguageSwitcher(
                      child: BlocSelector<PlayerCubit, NowPlaying, bool>(
                        selector: (music) => music.hasSong,
                        // The small video window keeps clear of the music bar.
                        builder: (context, hasSong) => VideoSessionHost(
                          clearance: MiniVideoWindow.clearanceFor(
                            landscape:
                                MediaQuery.orientationOf(context) ==
                                Orientation.landscape,
                            musicBar: hasSong,
                          ),
                          pictureInPicture: getIt<PictureInPictureService>(),
                          onExpand: () =>
                              AppRoute.router.push<void>(Routes.videoPlayer),
                          child: child ?? const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
