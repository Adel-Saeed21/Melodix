import 'package:melodix/features/player/presentation/logic/playback_progress_cubit.dart';
import 'package:melodix/features/player/domain/entities/playback_progress.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/widgets/app_snack_bar.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_artwork.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';
import 'package:melodix/features/player/presentation/utils/playback_error_text.dart';
import 'package:melodix/features/player/presentation/utils/player_rebuild_stats.dart';
import 'package:melodix/features/player/presentation/widgets/marquee_text.dart';
import 'package:melodix/features/player/presentation/widgets/player_controls.dart';
import 'package:melodix/features/player/presentation/widgets/player_progress.dart';
import 'package:melodix/features/player/presentation/widgets/player_queue_sheet.dart';

/// Compact player shown above the nav bar while a song is loaded. Hidden
/// when nothing is loaded and while the keyboard is open.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key, required this.onExpand});

  /// Opens the full player page.
  final VoidCallback onExpand;

  static const Duration _animation = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    // Own paint layer: the mini player's frequent updates (seek bar, time,
    // scrolling title) don't repaint the blurred nav bar or the page.
    return RepaintBoundary(
      child: BlocConsumer<PlayerCubit, NowPlaying>(
        listenWhen: (p, c) =>
            c.errorSequence != p.errorSequence && c.error != null,
        listener: (context, state) => AppSnackBar.show(
          context,
          playbackErrorText(state.error!),
          kind: AppSnackBarKind.error,
        ),
        builder: (context, state) {
          final visible = state.hasSong && !keyboardOpen;
          return AnimatedSwitcher(
            duration: _animation,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            ),
            child: visible
                ? switch (UiPreferencesScope.of(context).miniPlayer) {
                    MiniPlayerStyle.classic => _MiniPlayerCard(
                      key: const ValueKey('mini-player'),
                      state: state,
                      onExpand: onExpand,
                    ),
                    MiniPlayerStyle.capsule => _CapsuleMiniPlayer(
                      key: const ValueKey('mini-player-capsule'),
                      state: state,
                      onExpand: onExpand,
                    ),
                    MiniPlayerStyle.minimal => _MinimalMiniPlayer(
                      key: const ValueKey('mini-player-minimal'),
                      state: state,
                      onExpand: onExpand,
                    ),
                  }
                : const SizedBox(
                    key: ValueKey('no-player'),
                    width: double.infinity,
                  ),
          );
        },
      ),
    );
  }
}

class _MiniPlayerCard extends StatelessWidget {
  const _MiniPlayerCard({
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
      padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 6.h),
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
            padding: EdgeInsets.fromLTRB(10.w, 8.h, 4.w, 2.h),
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
                      tooltip: AppStrings.next,
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
                      tooltip: AppStrings.openQueue,
                      onPressed: () => showPlayerQueue(context),
                      icon: Icon(
                        Icons.queue_music_rounded,
                        size: 22.r,
                        color: onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                    IconButton(
                      tooltip: AppStrings.openPlayer,
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

/// The capsule design: a floating pill, the cover round inside a ring that
/// fills as the song plays, then play / pause and next. Tap it to open the
/// full player.
class _CapsuleMiniPlayer extends StatelessWidget {
  const _CapsuleMiniPlayer({
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
        elevation: 10,
        shadowColor: theme.primaryColor.withValues(alpha: 0.35),
        shape: const StadiumBorder(),
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

/// The minimal design: a flat bar (no shadow) with a thin progress line
/// along its top, the cover, the song and previous / play / next. Tap it to
/// open the full player.
class _MinimalMiniPlayer extends StatelessWidget {
  const _MinimalMiniPlayer({
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
