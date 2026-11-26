import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/presentation/logic/song_list_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/collection_page_scaffold.dart';
import 'package:melodix/features/music_library/presentation/widgets/favourites/favourites_collapsing_header.dart';
import 'package:melodix/features/music_library/presentation/widgets/favourites/favourites_hero.dart';
import 'package:melodix/features/music_library/presentation/widgets/favourites/favourites_tabs.dart';
import 'package:melodix/features/music_library/presentation/widgets/favourites/favourite_songs_tab.dart';
import 'package:melodix/features/music_library/presentation/widgets/favourites/favourite_videos_tab.dart';

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
                    height:
                        MediaQuery.paddingOf(context).top +
                        FavouritesTabs.height,
                  ),
                  // Expanded: the whole hero, then the tabs. (Prototypes are
                  // only measured, never shown.)
                  maxExtentPrototype: Column(
                    children: [
                      const FavouritesHero(),
                      SizedBox(height: FavouritesTabs.height),
                    ],
                  ),
                  child: const FavouritesCollapsingHeader(),
                ),
              ),
            ],
            body: const TabBarView(
              children: [FavouriteSongsTab(), FavouriteVideosTab()],
            ),
          ),
        ),
      ),
    );
  }
}
