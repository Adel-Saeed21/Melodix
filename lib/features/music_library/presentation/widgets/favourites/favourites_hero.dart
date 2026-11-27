import 'package:melodix/core/config/theme/app_accent.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/features/music_library/presentation/logic/song_list_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/gradient_hero.dart';
import 'package:melodix/features/video/presentation/logic/favorite_videos_cubit.dart';

class FavouritesHero extends StatelessWidget {
  const FavouritesHero({super.key});

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
