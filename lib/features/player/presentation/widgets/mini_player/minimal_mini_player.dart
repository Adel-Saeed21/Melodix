import 'package:melodix/features/player/presentation/logic/playback_progress_cubit.dart';
import 'package:melodix/features/player/domain/entities/playback_progress.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_artwork.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';
import 'package:melodix/features/player/presentation/widgets/player_controls.dart';
import 'package:melodix/features/player/presentation/widgets/player_progress.dart';

/// The minimal design: a flat bar (no shadow) with a thin progress line
/// along its top, the cover, the song and previous / play / next. Tap it to
/// open the full player.
class MinimalMiniPlayer extends StatelessWidget {
  const MinimalMiniPlayer({
    super.key,
    required this.state,
    required this.onExpand,
  });

  final NowPlaying state;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;
    final cubit = context.read<PlayerCubit>();
    final song = state.currentSong!;
    final radius = BorderRadius.circular(14.r);

    return Padding(
      padding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 6.h),
      child: Material(
        color: isDark
            ? theme.colorScheme.surfaceContainer
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Only the line follows the position ticks.
            RepaintBoundary(
              child:
                  BlocSelector<PlaybackProgressCubit, PlaybackProgress, double>(
                    selector: (p) => p.fraction,
                    builder: (context, fraction) => LinearProgressIndicator(
                      value: fraction,
                      minHeight: 2.5,
                      color: theme.primaryColor,
                      backgroundColor: onSurface.withValues(alpha: 0.08),
                    ),
                  ),
            ),
            Semantics(
              button: true,
              label: AppStrings.openPlayer,
              child: InkWell(
                onTap: onExpand,
                child: IconButtonTheme(
                  data: IconButtonThemeData(
                    style: IconButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(10.w, 6.h, 4.w, 6.h),
                    child: Row(
                      children: [
                        SongArtwork(songId: song.id, size: 40.r),
                        horizontalSpace(10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: onSurface,
                                  fontSize: AppTextSizes.base,
                                  fontWeight: FontWeightHelper.semiBold,
                                ),
                              ),
                              Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: onSurface.withValues(alpha: 0.6),
                                  fontSize: AppTextSizes.xs,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PreviousButton(iconSize: 24.r),
                        PlayPauseButton(
                          isPlaying: state.isPlaying,
                          isLoading: state.isLoading,
                          isCompleted: state.isCompleted,
                          size: 36.r,
                          onPressed: cubit.togglePlayPause,
                        ),
                        IconButton(
                          tooltip: AppStrings.next,
                          onPressed: state.hasNext ? cubit.next : null,
                          icon: Icon(Icons.skip_next_rounded, size: 24.r),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
