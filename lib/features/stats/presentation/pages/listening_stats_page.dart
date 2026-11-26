import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/widgets/melodix_mark.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_bloc.dart';
import 'package:melodix/features/music_library/presentation/logic/music_library_state.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_artwork.dart';
import 'package:melodix/features/settings/presentation/widgets/settings_section.dart';
import 'package:melodix/features/settings/presentation/widgets/settings_subpage.dart';
import 'package:melodix/features/stats/domain/listening_stats.dart';

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
            _HeroCard(stats: stats),
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
                    _RankRow(
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
                      _RankRow(
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.stats});

  final ListeningStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (accent, second) = accentPair(context);
    final on = theme.colorScheme.onPrimary;
    final hours = stats.listened.inHours;
    final minutes = stats.listened.inMinutes % 60;
    Widget tile(String value, String label) => Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: on,
                fontSize: AppTextSizes.xl,
                fontWeight: FontWeightHelper.bold,
              ),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: on.withValues(alpha: 0.8),
              fontSize: AppTextSizes.xs,
            ),
          ),
        ],
      ),
    );
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, second],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.4),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MelodixMark(size: 26.r, color: on),
              SizedBox(width: 10.w),
              Text(
                AppStrings.yourMelodix,
                style: TextStyle(
                  color: on,
                  fontSize: AppTextSizes.lg,
                  fontWeight: FontWeightHelper.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Text(
            AppStrings.statsListened,
            style: TextStyle(color: on.withValues(alpha: 0.8)),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              AppStrings.statsHours(hours, minutes),
              style: TextStyle(
                color: on,
                fontSize: 40.sp,
                height: 1.1,
                fontWeight: FontWeightHelper.bold,
              ),
            ),
          ),
          if (stats.topArtists.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              '${AppStrings.statsTopArtistLabel}: '
              '${stats.topArtists.first.artist}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: on,
                fontWeight: FontWeightHelper.semiBold,
              ),
            ),
          ],
          SizedBox(height: 18.h),
          Row(
            children: [
              tile('${stats.plays}', AppStrings.statsPlays),
              tile('${stats.songCount}', AppStrings.statsSongs),
              tile('${stats.favourites}', AppStrings.statsFavourites),
            ],
          ),
        ],
      ),
    );
  }
}

/// A ranked row: number, (picture), name, plays and a bar against the
/// most played.
class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.title,
    required this.plays,
    required this.most,
    this.subtitle,
    this.leading,
  });

  final int rank;
  final String title;
  final String? subtitle;
  final int plays;
  final int most;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          SizedBox(
            width: 22.w,
            child: Text(
              '$rank',
              style: TextStyle(
                color: rank == 1
                    ? theme.primaryColor
                    : onSurface.withValues(alpha: 0.5),
                fontSize: AppTextSizes.lg,
                fontWeight: FontWeightHelper.bold,
              ),
            ),
          ),
          if (leading case final leading?) ...[leading, SizedBox(width: 12.w)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: onSurface,
                    fontWeight: FontWeightHelper.semiBold,
                  ),
                ),
                if (subtitle case final subtitle?)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.6),
                      fontSize: AppTextSizes.sm,
                    ),
                  ),
                SizedBox(height: 6.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: most == 0 ? 0 : plays / most,
                    minHeight: 4,
                    color: theme.primaryColor,
                    backgroundColor: onSurface.withValues(alpha: 0.08),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            AppStrings.statsTimes(plays),
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.6),
              fontSize: AppTextSizes.sm,
            ),
          ),
        ],
      ),
    );
  }
}
