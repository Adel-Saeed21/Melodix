import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/music_library/domain/entities/song.dart';
import 'package:melodix/features/music_library/presentation/logic/song_actions_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_actions_scope.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_artwork.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_options_button.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';
import 'package:melodix/features/player/presentation/widgets/drag_to_dismiss.dart';
import 'package:melodix/features/player/presentation/utils/player_rebuild_stats.dart';
import 'package:melodix/features/player/presentation/widgets/marquee_text.dart';
import 'package:melodix/features/player/presentation/widgets/player_controls.dart';
import 'package:melodix/features/player/presentation/widgets/player_progress.dart';
import 'package:melodix/features/player/presentation/widgets/player_queue_sheet.dart';

/// Full player: large cover, song info, seek bar and all controls. Reads the
/// same [PlayerCubit] as the mini player, so both always match.
class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({super.key});

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> {
  bool _closing = false;

  /// Leaves the page once if nothing is loaded anymore.
  void _closeOnce() {
    if (_closing) return;
    _closing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SongActionsScope(
      // Pull the page down (or tap ⌄) to go back to the mini player.
      child: DragToDismiss(
        onDismiss: () => Navigator.of(context).maybePop(),
        child: Scaffold(
          body: SafeArea(
            child: BlocBuilder<PlayerCubit, NowPlaying>(
              builder: (context, state) {
                final song = state.currentSong;
                if (song == null) {
                  _closeOnce();
                  return const SizedBox.shrink();
                }
                return _NowPlayingBody(state: state, song: song);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NowPlayingBody extends StatelessWidget {
  const _NowPlayingBody({required this.state, required this.song});

  final NowPlaying state;
  final Song song;

  @override
  Widget build(BuildContext context) {
    // ignore: invalid_use_of_visible_for_testing_member
    PlayerRebuildStats.hit('nowPlayingBody');
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final cubit = context.read<PlayerCubit>();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          verticalSpace(8),
          Row(
            children: [
              _CircleIconButton(
                icon: Icons.keyboard_arrow_down_rounded,
                tooltip: AppStrings.closePlayer,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Text(
                  AppStrings.nowPlaying,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: AppTextSizes.lg,
                    fontWeight: FontWeightHelper.bold,
                  ),
                ),
              ),
              SongOptionsButton(song: song),
            ],
          ),
          verticalSpace(24),
          // Cover: as large as fits, square, rounded.
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Center(
                child: SongArtwork(
                  key: ValueKey(song.id),
                  songId: song.id,
                  size: constraints.biggest.shortestSide,
                ),
              ),
            ),
          ),
          verticalSpace(28),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MarqueeText(
                      song.title,
                      key: ValueKey('title-${song.id}'),
                      style: TextStyle(
                        color: onSurface,
                        fontSize: AppTextSizes.xl,
                        fontWeight: FontWeightHelper.bold,
                      ),
                    ),
                    verticalSpace(4),
                    Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.6),
                        fontSize: AppTextSizes.base,
                      ),
                    ),
                  ],
                ),
              ),
              _FavouriteButton(song: song),
            ],
          ),
          verticalSpace(20),
          const PlayerSeekBar(),
          verticalSpace(6),
          const PlaybackTimesRow(),
          verticalSpace(12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RepeatButton(
                mode: state.repeatMode,
                onPressed: cubit.cycleRepeat,
                size: 24.r,
              ),
              PreviousButton(iconSize: 36.r),
              PlayPauseButton(
                isPlaying: state.isPlaying,
                isLoading: state.isLoading,
                isCompleted: state.isCompleted,
                size: 68.r,
                onPressed: cubit.togglePlayPause,
              ),
              IconButton(
                tooltip: AppStrings.next,
                iconSize: 36.r,
                onPressed: state.hasNext ? cubit.next : null,
                icon: const Icon(Icons.skip_next_rounded),
              ),
              IconButton(
                tooltip: AppStrings.shuffle,
                onPressed: cubit.toggleShuffle,
                icon: Icon(
                  Icons.shuffle_rounded,
                  size: 24.r,
                  color: state.shuffle
                      ? theme.primaryColor
                      : onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          verticalSpace(4),
          TextButton.icon(
            onPressed: () => showPlayerQueue(context),
            icon: Icon(
              Icons.queue_music_rounded,
              color: onSurface.withValues(alpha: 0.7),
            ),
            label: Text(
              AppStrings.queue,
              style: TextStyle(color: onSurface.withValues(alpha: 0.7)),
            ),
          ),
          verticalSpace(8),
        ],
      ),
    );
  }
}

/// Heart showing whether [song] is a favourite, live: it follows the song's
/// own flag in storage (no scan of the library), so a change made anywhere
/// (a menu, the notification's ♥) shows here at once.
class _FavouriteButton extends StatefulWidget {
  const _FavouriteButton({required this.song});

  final Song song;

  @override
  State<_FavouriteButton> createState() => _FavouriteButtonState();
}

class _FavouriteButtonState extends State<_FavouriteButton> {
  late Stream<bool> _favorite = _watch();

  Stream<bool> _watch() =>
      context.read<SongActionsCubit>().watchFavorite(widget.song);

  @override
  void didUpdateWidget(_FavouriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) _favorite = _watch();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return StreamBuilder<bool>(
      stream: _favorite,
      // The queue's copy until storage answers (right away, normally).
      initialData: widget.song.isFavorite,
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? widget.song.isFavorite;
        return IconButton(
          tooltip: isFavorite
              ? AppStrings.removeFromFavourites
              : AppStrings.addToFavourites,
          onPressed: () =>
              context.read<SongActionsCubit>().toggleFavorite(widget.song),
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? primary : onSurface.withValues(alpha: 0.7),
          ),
        );
      },
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: onSurface.withValues(alpha: 0.08),
      ),
      icon: Icon(icon, color: onSurface),
    );
  }
}
