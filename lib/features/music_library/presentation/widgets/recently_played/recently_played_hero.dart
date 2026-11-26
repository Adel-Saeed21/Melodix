import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_colors.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/presentation/widgets/gradient_hero.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';

class RecentlyPlayedHero extends StatelessWidget {
  const RecentlyPlayedHero({super.key, required this.songs});

  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerCubit>();
    final hasSongs = songs.isNotEmpty;
    return GradientHero(
      colors: AppColors.recentGradient,
      icon: Icons.history_rounded,
      label: AppStrings.lastPlayed,
      title: AppStrings.recentlyPlayed,
      details: AppStrings.songsCount(songs.length),
      onPlay: hasSongs
          ? () => player.playSongs(songs, 0, title: AppStrings.recentlyPlayed)
          : null,
      onShuffle: hasSongs
          ? () => player.shufflePlay(songs, title: AppStrings.recentlyPlayed)
          : null,
    );
  }
}
