import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/theme/app_colors.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/presentation/widgets/gradient_hero.dart';
import 'package:melodix/features/music_library/presentation/logic/song_playback.dart';

class RecentlyPlayedHero extends StatelessWidget {
  const RecentlyPlayedHero({super.key, required this.songs});

  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    final player = context.read<SongPlayback>();
    final hasSongs = songs.isNotEmpty;
    return GradientHero(
      colors: AppColors.recentGradient,
      icon: Icons.history_rounded,
      label: context.l10n.lastPlayed,
      title: context.l10n.recentlyPlayed,
      details: context.l10n.songsCount(songs.length),
      onPlay: hasSongs
          ? () => player.playSongs(songs, 0, title: context.l10n.recentlyPlayed)
          : null,
      onShuffle: hasSongs
          ? () => player.shufflePlay(songs, title: context.l10n.recentlyPlayed)
          : null,
    );
  }
}
