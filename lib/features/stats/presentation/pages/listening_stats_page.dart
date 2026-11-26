import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_state.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_artwork.dart';
import 'package:melodix/core/widgets/settings/settings_section.dart';
import 'package:melodix/core/widgets/settings/settings_subpage.dart';
import 'package:melodix/features/stats/domain/listening_stats.dart';
import 'package:melodix/features/stats/presentation/widgets/listening_stats/stats_hero_card.dart';
import 'package:melodix/features/stats/presentation/widgets/listening_stats/stats_rank_row.dart';

/// "Your Melodix": hours listened, plays, top songs and artists, from the
/// library's play counts. A big accent card on top, made to screenshot.
class ListeningStatsPage extends StatelessWidget {
  const ListeningStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<MusicLibraryBloc, MusicLibraryState, List<Song>>(
      selector: (state) => state.songs,
      builder: (context, songs) {
        final stats = ListeningStats.of(songs);
        return SettingsSubpage(
          title: AppStrings.yourMelodix,
          children: [
            StatsHeroCard(stats: stats),
            if (stats.isEmpty)
              const SettingsSection(
                icon: Icons.music_note_rounded,
                title: AppStrings.yourMelodix,
                children: [SettingRow(title: AppStrings.statsEmpty)],
              )
            else ...[
              SettingsSection(
                icon: Icons.emoji_events_rounded,
                title: AppStrings.statsTopSongs,
                children: [
                  for (var i = 0; i < stats.topSongs.length; i++)
                    StatsRankRow(
                      rank: i + 1,
                      title: stats.topSongs[i].title,
                      subtitle: stats.topSongs[i].artist,
                      plays: stats.topSongs[i].playCount,
                      most: stats.topSongs.first.playCount,
                      leading: SongArtwork(
                        songId: stats.topSongs[i].id,
                        size: 40.r,
                      ),
                    ),
                ],
              ),
              if (stats.topArtists.isNotEmpty)
                SettingsSection(
                  icon: Icons.mic_external_on_rounded,
                  title: AppStrings.statsTopArtists,
                  children: [
                    for (var i = 0; i < stats.topArtists.length; i++)
                      StatsRankRow(
                        rank: i + 1,
                        title: stats.topArtists[i].artist,
                        plays: stats.topArtists[i].plays,
                        most: stats.topArtists.first.plays,
                      ),
                  ],
                ),
            ],
          ],
        );
      },
    );
  }
}
