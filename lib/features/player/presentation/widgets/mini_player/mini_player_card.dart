import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_artwork.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';
import 'package:melodix/features/player/presentation/utils/player_rebuild_stats.dart';
import 'package:melodix/features/player/presentation/widgets/marquee_text.dart';
import 'package:melodix/features/player/presentation/widgets/player_controls.dart';
import 'package:melodix/features/player/presentation/widgets/player_progress.dart';
import 'package:melodix/features/player/presentation/widgets/player_queue_sheet.dart';

class MiniPlayerCard extends StatelessWidget {
  const MiniPlayerCard({
    super.key,
    required this.state,
    required this.onExpand,
  });

  final NowPlaying state;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    // ignore: invalid_use_of_visible_for_testing_member
    PlayerRebuildStats.hit('miniCard');
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;
    final cubit = context.read<PlayerCubit>();
    final song = state.currentSong!;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(12.w, 0, 12.w, 6.h),
      child: Material(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh
            : theme.colorScheme.surface,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20.r),
        clipBehavior: Clip.antiAlias,
        // Compact buttons leave room for the title and the seek bar.
        child: IconButtonTheme(
          data: IconButtonThemeData(
            style: IconButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.all(6.r),
              minimumSize: Size.square(36.r),
            ),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(10.w, 8.h, 4.w, 2.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Tapping the song also opens the full player.
                    Expanded(
                      child: InkWell(
                        onTap: onExpand,
                        borderRadius: BorderRadius.circular(12.r),
                        child: Row(
                          children: [
                            SongArtwork(songId: song.id, size: 44.r),
                            horizontalSpace(10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MarqueeText(
                                    song.title,
                                    key: ValueKey(song.id),
                                    style: TextStyle(
                                      color: onSurface,
                                      fontSize: AppTextSizes.base,
                                      fontWeight: FontWeightHelper.bold,
                                    ),
                                  ),
                                  verticalSpace(2),
                                  Text(
                                    song.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: onSurface.withValues(alpha: 0.6),
                                      fontSize: AppTextSizes.sm,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PreviousButton(iconSize: 26.r),
                    PlayPauseButton(
                      isPlaying: state.isPlaying,
                      isLoading: state.isLoading,
                      isCompleted: state.isCompleted,
                      size: 40.r,
                      onPressed: cubit.togglePlayPause,
                    ),
                    IconButton(
                      tooltip: context.l10n.next,
                      onPressed: state.hasNext ? cubit.next : null,
                      icon: Icon(Icons.skip_next_rounded, size: 26.r),
                    ),
                  ],
                ),
                Row(
                  children: [
                    RepeatButton(
                      mode: state.repeatMode,
                      onPressed: cubit.cycleRepeat,
                      size: 20.r,
                    ),
                    Expanded(child: const PlayerSeekBar(compact: true)),
                    horizontalSpace(8),
                    ElapsedRemainingLabel(
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.7),
                        fontSize: AppTextSizes.xs,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    // Opens the list the song is playing from.
                    IconButton(
                      tooltip: context.l10n.openQueue,
                      onPressed: () => showPlayerQueue(context),
                      icon: Icon(
                        Icons.queue_music_rounded,
                        size: 22.r,
                        color: onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.openPlayer,
                      onPressed: onExpand,
                      icon: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        size: 24.r,
                        color: onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
