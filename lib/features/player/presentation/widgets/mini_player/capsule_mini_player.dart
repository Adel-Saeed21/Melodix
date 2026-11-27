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
import 'package:melodix/features/player/presentation/widgets/marquee_text.dart';
import 'package:melodix/features/player/presentation/widgets/player_controls.dart';

/// The capsule design: a flat pill (no shadow), the cover round inside a ring that
/// fills as the song plays, then play / pause and next. Tap it to open the
/// full player.
class CapsuleMiniPlayer extends StatelessWidget {
  const CapsuleMiniPlayer({
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
    final ring = 50.r;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h),
      child: Material(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh
            : theme.colorScheme.surface,
        // No shadow: a hairline edge (like the nav bar's) keeps the pill
        // apart from a light background.
        shape: StadiumBorder(
          side: BorderSide(
            color: onSurface.withValues(alpha: isDark ? 0.12 : 0.08),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          button: true,
          label: AppStrings.openPlayer,
          child: InkWell(
            onTap: onExpand,
            child: Padding(
              padding: EdgeInsets.fromLTRB(6.r, 6.r, 8.r, 6.r),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: ring,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(4.r),
                          child: SongArtwork(
                            songId: song.id,
                            size: ring - 8.r,
                            circle: true,
                          ),
                        ),
                        // Only the ring follows the position ticks.
                        RepaintBoundary(
                          child:
                              BlocSelector<
                                PlaybackProgressCubit,
                                PlaybackProgress,
                                double
                              >(
                                selector: (p) => p.fraction,
                                builder: (context, fraction) =>
                                    CircularProgressIndicator(
                                      value: fraction,
                                      strokeWidth: 2.5,
                                      strokeCap: StrokeCap.round,
                                      color: theme.primaryColor,
                                      backgroundColor: onSurface.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                              ),
                        ),
                      ],
                    ),
                  ),
                  horizontalSpace(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MarqueeText(
                          song.title,
                          key: ValueKey('capsule-${song.id}'),
                          style: TextStyle(
                            color: onSurface,
                            fontSize: AppTextSizes.base,
                            fontWeight: FontWeightHelper.bold,
                          ),
                        ),
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
                  PlayPauseButton(
                    isPlaying: state.isPlaying,
                    isLoading: state.isLoading,
                    isCompleted: state.isCompleted,
                    size: 42.r,
                    onPressed: cubit.togglePlayPause,
                  ),
                  IconButton(
                    tooltip: AppStrings.next,
                    onPressed: state.hasNext ? cubit.next : null,
                    icon: Icon(Icons.skip_next_rounded, size: 28.r),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
