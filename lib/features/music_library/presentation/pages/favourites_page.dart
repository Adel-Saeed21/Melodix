import 'package:melodix/core/config/theme/app_accent.dart';
import 'package:melodix/features/video/presentation/widgets/video_row_actions.dart';
import 'package:melodix/core/models/load_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/core/widgets/whole_pixel_height.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/presentation/logic/song_list_cubit.dart';
import 'package:melodix/core/utils/duration_format.dart';
import 'package:melodix/features/music_library/presentation/widgets/collection_page_scaffold.dart';
import 'package:melodix/features/music_library/presentation/widgets/gradient_hero.dart';
import 'package:melodix/core/widgets/library_status_view.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_list_body.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/presentation/logic/favorite_videos_cubit.dart';
import 'package:melodix/features/video/presentation/navigation/video_player_navigation.dart';
import 'package:melodix/features/video/presentation/widgets/video_tile.dart';

/// What the user ♥'d, in two tabs: Songs and Videos. Both are live: an
/// item favourited anywhere appears at once, and leaves when unfavourited.
///
/// The hero collapses as the page scrolls; the tabs then stay pinned under
/// the app bar, so switching never needs a scroll back to the top.
class FavouritesPage extends StatelessWidget {
  const FavouritesPage({super.key});

  /// The favourites among the library's songs, in library order.
  static List<Song> favouritesOf(List<Song> songs) => [
    for (final song in songs)
      if (song.isFavorite) song,
  ];

  @override
  Widget build(BuildContext context) {
    // Favourite videos come from the app-wide FavoriteVideosCubit.
    return BlocProvider(
      create: (context) => SongListCubit.live(
        context.read<MusicLibraryBloc>().librarySongs().map(favouritesOf),
      ),
      child: DefaultTabController(
        length: 2,
        child: CollectionPageScaffold(
          extendBehindAppBar: true,
          body: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
                sliver: SliverResizingHeader(
                  // Collapsed: the app bar's height, then the tabs.
                  // (The body's top padding already counts the app bar: the
                  // body extends behind it.)
                  minExtentPrototype: SizedBox(
                    height: MediaQuery.paddingOf(context).top + _Tabs.height,
                  ),
                  // Expanded: the whole hero, then the tabs. (Prototypes are
                  // only measured, never shown.)
                  maxExtentPrototype: Column(
                    children: [
                      const _Hero(),
                      SizedBox(height: _Tabs.height),
                    ],
                  ),
                  child: const _CollapsingHeader(),
                ),
              ),
            ],
            body: const TabBarView(children: [_SongsTab(), _VideosTab()]),
          ),
        ),
      ),
    );
  }
}

/// The hero over the tabs. As it shrinks, the hero slides up out of view
/// and a solid gradient bar (with the title) fades in behind the app bar.
class _CollapsingHeader extends StatelessWidget {
  const _CollapsingHeader();

  @override
  Widget build(BuildContext context) {
    // Status bar + app bar (the body extends behind the app bar).
    final barHeight = MediaQuery.paddingOf(context).top;
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 0 while the hero has room for itself (the bar's height is
              // the lowest it can go), 1 once only the bar is left.
              final room = constraints.maxHeight - barHeight;
              final collapsed = (1 - room / (barHeight * 1.5)).clamp(0.0, 1.0);
              return ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const OverflowBox(
                      alignment: Alignment.bottomCenter,
                      maxHeight: double.infinity,
                      child: _Hero(),
                    ),
                    if (collapsed > 0)
                      Opacity(opacity: collapsed, child: const _CollapsedBar()),
                  ],
                ),
              );
            },
          ),
        ),
        const _Tabs(),
      ],
    );
  }
}

class _CollapsedBar extends StatelessWidget {
  const _CollapsedBar();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AccentColors.favouritesGradient(
            Theme.of(context).primaryColor,
          ),
        ),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: kToolbarHeight,
          child: Center(
            child: Text(
              AppStrings.favourites,
              style: TextStyle(
                color: Colors.white,
                fontSize: AppTextSizes.lg,
                fontWeight: FontWeightHelper.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final songs = context.select((SongListCubit c) => c.state.songs.length);
    final videos = context.select(
      (FavoriteVideosCubit c) => c.state.videos.length,
    );
    return GradientHero(
      colors: AccentColors.favouritesGradient(Theme.of(context).primaryColor),
      icon: Icons.favorite_rounded,
      glow: true,
      label: AppStrings.yourFavourites,
      title: AppStrings.favourites,
      details:
          '${AppStrings.songsCount(songs)} · ${AppStrings.videosCount(videos)}',
      // Play / Shuffle are for songs: they're in the Songs tab.
      showActions: false,
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs();

  static const List<Widget> _tabs = [
    Tab(icon: Icon(Icons.music_note_rounded), text: AppStrings.songs),
    Tab(icon: Icon(Icons.movie_rounded), text: AppStrings.videos),
  ];

  /// The tabs' height (fixed by Material: it doesn't grow with text size).
  static double get height => const TabBar(tabs: _tabs).preferredSize.height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: TabBar(
        dividerColor: onSurface.withValues(alpha: 0.08),
        indicatorColor: theme.primaryColor,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: onSurface,
        unselectedLabelColor: onSurface.withValues(alpha: 0.5),
        labelStyle: TextStyle(
          fontSize: AppTextSizes.lg,
          fontWeight: FontWeightHelper.bold,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: AppTextSizes.lg,
          fontWeight: FontWeightHelper.medium,
        ),
        tabs: _tabs,
      ),
    );
  }
}

class _SongsTab extends StatelessWidget {
  const _SongsTab();

  @override
  Widget build(BuildContext context) {
    return SongListBody(
      insideNestedScrollView: true,
      queueTitle: AppStrings.favourites,
      header: (songs) =>
          songs.isEmpty ? const SizedBox.shrink() : _SongsActions(songs: songs),
      emptyView: const Padding(
        padding: EdgeInsets.only(top: 8),
        child: LibraryStatusView(
          icon: Icons.favorite_border_rounded,
          title: AppStrings.noFavouritesTitle,
          message: AppStrings.noFavouritesSubtitle,
        ),
      ),
    );
  }
}

/// "12 songs · 48 min" with Shuffle and Play, above the favourite songs.
class _SongsActions extends StatelessWidget {
  const _SongsActions({required this.songs});

  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerCubit>();
    final theme = Theme.of(context);
    final total = songs.fold(Duration.zero, (sum, s) => sum + s.duration);
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 16.w, 4.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${AppStrings.songsCount(songs.length)} · '
              '${formatTotalDuration(total)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: AppTextSizes.sm,
                fontWeight: FontWeightHelper.medium,
              ),
            ),
          ),
          IconButton.filledTonal(
            tooltip: AppStrings.shufflePlay,
            onPressed: () =>
                player.shufflePlay(songs, title: AppStrings.favourites),
            icon: const Icon(Icons.shuffle_rounded),
          ),
          horizontalSpace(8),
          IconButton.filled(
            tooltip: AppStrings.playAll,
            style: IconButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            onPressed: () =>
                player.playSongs(songs, 0, title: AppStrings.favourites),
            icon: const Icon(Icons.play_arrow_rounded),
          ),
        ],
      ),
    );
  }
}

class _VideosTab extends StatelessWidget {
  const _VideosTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoriteVideosCubit, FavoriteVideosState>(
      builder: (context, state) {
        final overlap = SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        );
        final Widget content;
        if (state.status == LoadStatus.loading && state.videos.isEmpty) {
          content = const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (state.videos.isEmpty) {
          content = SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: state.status == LoadStatus.failure
                  ? LibraryStatusView(
                      icon: Icons.error_outline_rounded,
                      title: AppStrings.libraryErrorTitle,
                      message: state.errorMessage ?? '',
                    )
                  : const LibraryStatusView(
                      icon: Icons.favorite_border_rounded,
                      title: AppStrings.noFavouriteVideosTitle,
                      message: AppStrings.noFavouriteVideosSubtitle,
                    ),
            ),
          );
        } else {
          // Fixed-height rows (measured once), like the song lists.
          content = SliverPrototypeExtentList.builder(
            prototypeItem: _row(context, state.videos, 0),
            itemCount: state.videos.length,
            itemBuilder: (_, index) => _row(context, state.videos, index),
          );
        }
        return CustomScrollView(
          key: const PageStorageKey('favourite-videos'),
          slivers: [
            overlap,
            SliverPadding(padding: EdgeInsets.only(top: 8.h)),
            content,
            SliverPadding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 16.h,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _row(BuildContext context, List<Video> videos, int index) {
    final video = videos[index];
    return WholePixelHeight(
      child: VideoTile(
        key: ValueKey(video.id),
        video: video,
        // Next / previous in the player move through the favourites.
        onTap: () => openVideoPlayer(context, videos, index),
        trailing: VideoRowActions(video: video),
      ),
    );
  }
}
