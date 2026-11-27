import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_artwork.dart';
import 'package:melodix/core/widgets/settings/settings_section.dart';
import 'package:melodix/core/widgets/settings/settings_subpage.dart';
import 'package:melodix/features/stats/domain/listening_stats.dart';
import 'package:melodix/features/stats/presentation/logic/listening_stats_cubit.dart';
import 'package:melodix/features/stats/presentation/widgets/listening_stats/stats_hero_card.dart';
import 'package:melodix/features/stats/presentation/widgets/listening_stats/stats_rank_row.dart';

/// "Your Melodix": hours listened, plays, top songs and artists, from the
/// whole listening history (not just what the music filters show). A big
/// accent card on top, made to screenshot.
class ListeningStatsPage extends StatelessWidget {
  const ListeningStatsPage({super.key, this.createCubit});

  /// Tests pass their own; otherwise the app's (from get_it).
  final ListeningStatsCubit Function()? createCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => createCubit?.call() ?? getIt<ListeningStatsCubit>(),
      child: BlocBuilder<ListeningStatsCubit, ListeningStats?>(
        builder: (context, loaded) {
          if (loaded == null) {
            return SettingsSubpage(
              title: context.l10n.yourMelodix,
              children: [Center(child: CircularProgressIndicator())],
            );
          }
          final stats = loaded;
          return SettingsSubpage(
            title: context.l10n.yourMelodix,
            children: [
              StatsHeroCard(stats: stats),
              if (stats.isEmpty)
                SettingsSection(
                  icon: Icons.music_note_rounded,
                  title: context.l10n.yourMelodix,
                  children: [SettingRow(title: context.l10n.statsEmpty)],
                )
              else ...[
                SettingsSection(
                  icon: Icons.emoji_events_rounded,
                  title: context.l10n.statsTopSongs,
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
                    title: context.l10n.statsTopArtists,
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
      ),
    );
  }
}
