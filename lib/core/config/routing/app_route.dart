import 'package:melodix/features/video/presentation/pages/video_player_page.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:material_ui/material_ui.dart';

import 'package:go_router/go_router.dart';
import 'package:melodix/core/config/routing/routes.dart';
import 'package:melodix/features/player/domain/repositories/equalizer_engine.dart';
import 'package:melodix/features/player/presentation/pages/equalizer_page.dart';
import 'package:melodix/features/settings/presentation/pages/library_filters_page.dart';
import 'package:melodix/features/stats/presentation/pages/listening_stats_page.dart';
import 'package:melodix/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:melodix/features/music_library/domain/entities/album.dart';
import 'package:melodix/features/music_library/domain/entities/artist.dart';
import 'package:melodix/features/music_library/domain/entities/playlist.dart';
import 'package:melodix/features/music_library/presentation/pages/album_details_page.dart';
import 'package:melodix/features/music_library/presentation/pages/artist_details_page.dart';
import 'package:melodix/features/music_library/presentation/pages/favourites_page.dart';
import 'package:melodix/features/music_library/presentation/pages/recently_played_page.dart';
import 'package:melodix/features/music_library/presentation/pages/playlist_details_page.dart';
import 'package:melodix/features/navigation/presentation/pages/main_nav_shell.dart';
import 'package:melodix/features/player/presentation/pages/now_playing_page.dart';
import 'package:melodix/features/splash /presentation/splash_screen.dart';

class AppRoute {
  AppRoute._();

  static CustomTransitionPage<void> _buildPageWithTransition({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  static final GoRouter router = GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: Routes.splash,
        name: Routes.splash,
        pageBuilder: (context, state) {
          return _buildPageWithTransition(
            key: state.pageKey,
            child: const SplashScreen(),
          );
        },
      ),
      GoRoute(
        path: Routes.onboarding,
        name: Routes.onboarding,
        pageBuilder: (context, state) {
          return _buildPageWithTransition(
            key: state.pageKey,
            child: const OnboardingPage(),
          );
        },
      ),

      GoRoute(
        path: Routes.homeScreen,
        name: Routes.homeScreen,
        pageBuilder: (context, state) {
          return _buildPageWithTransition(
            key: state.pageKey,
            child: const MainNavShell(),
          );
        },
      ),

      // Detail pages need the Album / Artist passed as `extra`; without it
      // (e.g. a restored deep link) go back home instead of crashing.
      GoRoute(
        path: Routes.albumDetails,
        name: Routes.albumDetails,
        redirect: (context, state) =>
            state.extra is Album ? null : Routes.homeScreen,
        pageBuilder: (context, state) {
          return _buildPageWithTransition(
            key: state.pageKey,
            child: AlbumDetailsPage(album: state.extra! as Album),
          );
        },
      ),
      GoRoute(
        path: Routes.artistDetails,
        name: Routes.artistDetails,
        redirect: (context, state) =>
            state.extra is Artist ? null : Routes.homeScreen,
        pageBuilder: (context, state) {
          return _buildPageWithTransition(
            key: state.pageKey,
            child: ArtistDetailsPage(artist: state.extra! as Artist),
          );
        },
      ),
      GoRoute(
        path: Routes.equalizer,
        name: Routes.equalizer,
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: EqualizerPage(supported: getIt<EqualizerEngine>().isSupported),
        ),
      ),
      GoRoute(
        path: Routes.listeningStats,
        name: Routes.listeningStats,
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const ListeningStatsPage(),
        ),
      ),
      GoRoute(
        path: Routes.libraryFilters,
        name: Routes.libraryFilters,
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const LibraryFiltersPage(),
        ),
      ),
      GoRoute(
        path: Routes.playlistDetails,
        name: Routes.playlistDetails,
        redirect: (context, state) =>
            state.extra is Playlist ? null : Routes.homeScreen,
        pageBuilder: (context, state) {
          return _buildPageWithTransition(
            key: state.pageKey,
            child: PlaylistDetailsPage(playlist: state.extra! as Playlist),
          );
        },
      ),
      GoRoute(
        path: Routes.favourites,
        name: Routes.favourites,
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const FavouritesPage(),
        ),
      ),
      GoRoute(
        path: Routes.recentlyPlayed,
        name: Routes.recentlyPlayed,
        pageBuilder: (context, state) => _buildPageWithTransition(
          key: state.pageKey,
          child: const RecentlyPlayedPage(),
        ),
      ),
      // Shows the app's video session; with no video open, back home.
      GoRoute(
        path: Routes.videoPlayer,
        name: Routes.videoPlayer,
        redirect: (context, state) =>
            getIt<VideoPlayerCubit>().state.isActive ? null : Routes.homeScreen,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const VideoPlayerPage(),
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      // The full player slides up from the mini player.
      GoRoute(
        path: Routes.nowPlaying,
        name: Routes.nowPlaying,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const NowPlayingPage(),
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            );
          },
        ),
      ),
    ],
  );
}
