import 'dart:async';

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
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/features/lyrics/domain/repositories/lyrics_repository.dart';
import 'package:melodix/features/lyrics/presentation/logic/lyrics_cubit.dart';
import 'package:melodix/features/lyrics/presentation/widgets/lyrics_view.dart';
import 'package:melodix/features/player/presentation/widgets/now_playing_actions.dart';
import 'package:melodix/features/player/presentation/widgets/now_playing_backdrop.dart';

/// Full player: large cover, song info, seek bar and all controls. Reads the
/// same [PlayerCubit] as the mini player, so both always match.
class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({super.key});

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> {
  bool _closing = false;

  /// Lyrics in place of the cover.
  bool _showLyrics = false;

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
        child: BlocProvider(
          // Made the first time lyrics are shown.
          create: (_) => LyricsCubit(getIt<LyricsRepository>()),
          child: Scaffold(
            body: BlocBuilder<PlayerCubit, NowPlaying>(
              builder: (context, state) {
                final song = state.currentSong;
                if (song == null) {
                  _closeOnce();
                  return const SizedBox.shrink();
                }
                return Stack(
                  children: [
                    Positioned.fill(child: NowPlayingBackdrop(songId: song.id)),
                    SafeArea(
                      child: _NowPlayingBody(
                        state: state,
                        song: song,
                        showLyrics: _showLyrics,
                        onLyrics: () =>
                            setState(() => _showLyrics = !_showLyrics),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NowPlayingBody extends StatelessWidget {
  const _NowPlayingBody({
    required this.state,
    required this.song,
    required this.showLyrics,
    required this.onLyrics,
  });

  final NowPlaying state;
  final Song song;
  final bool showLyrics;
  final VoidCallback onLyrics;

  @override
  Widget build(BuildContext context) {
    // ignore: invalid_use_of_visible_for_testing_member
    PlayerRebuildStats.hit('nowPlayingBody');
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final cubit = context.read<PlayerCubit>();

    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final header = Row(
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
    );
    final titleRow = Row(
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
    );
    final controls = Row(
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
    );
    final actionsRow = NowPlayingActions(
      showingLyrics: showLyrics,
      onLyrics: onLyrics,
    );
    if (showLyrics) {
      // The lyrics follow the song playing (after this frame: loading
      // them changes state).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) unawaited(context.read<LyricsCubit>().show(song));
      });
    }
    Widget cover(BoxConstraints constraints) => AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: showLyrics
          ? const LyricsView(key: ValueKey('lyrics'))
          : Center(
              key: const ValueKey('cover'),
              child: SongArtwork(
                key: ValueKey(song.id),
                songId: song.id,
                size: constraints.biggest.shortestSide,
              ),
            ),
    );

    if (landscape) {
      // Phone on its side: the cover on the left, as tall as the screen;
      // everything else beside it.
      return Padding(
        padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 8.h),
        child: Row(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(builder: (_, c) => cover(c)),
            ),
            horizontalSpace(32),
            Expanded(
              child: Center(
                // Scrolls only if it can't fit (very large text).
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      header,
                      verticalSpace(8),
                      titleRow,
                      verticalSpace(12),
                      const PlayerSeekBar(),
                      verticalSpace(4),
                      const PlaybackTimesRow(),
                      verticalSpace(8),
                      controls,
                      actionsRow,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          verticalSpace(8),
          header,
          verticalSpace(24),
          // Cover: as large as fits, square, rounded.
          Expanded(child: LayoutBuilder(builder: (_, c) => cover(c))),
          verticalSpace(28),
          titleRow,
          verticalSpace(20),
          const PlayerSeekBar(),
          verticalSpace(6),
          const PlaybackTimesRow(),
          verticalSpace(12),
          controls,
          verticalSpace(4),
          actionsRow,
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
