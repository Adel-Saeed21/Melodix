import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';
import 'package:melodix/features/player/presentation/utils/playback_time_format.dart';
import 'package:melodix/features/player/presentation/widgets/player_controls.dart';
import 'package:melodix/features/player/domain/entities/playback_progress.dart';
import 'package:melodix/features/player/presentation/logic/playback_progress_cubit.dart';

// The only player widgets that follow position ticks: they listen to
// [PlaybackProgressCubit] (each selecting just what it shows); the rest of
// the player UI follows [PlayerCubit], which doesn't change per tick.

/// The seek bar, following the current position.
class PlayerSeekBar extends StatelessWidget {
  const PlayerSeekBar({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlaybackProgressCubit, PlaybackProgress>(
      builder: (context, progress) => SeekBar(
        compact: compact,
        position: progress.position,
        duration: progress.duration,
        onSeek: context.read<PlayerCubit>().seek,
      ),
    );
  }
}

/// "01:35 / -02:40". Rebuilds only when the shown text changes (about once
/// a second), not on every position tick.
class ElapsedRemainingLabel extends StatelessWidget {
  const ElapsedRemainingLabel({super.key, required this.style});

  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PlaybackProgressCubit, PlaybackProgress, String>(
      selector: (progress) =>
          formatElapsedAndRemaining(progress.position, progress.remaining),
      builder: (context, text) => FixedSizeTimeText(text, style: style),
    );
  }
}

/// Elapsed time on the left, remaining time on the right (full player).
class PlaybackTimesRow extends StatelessWidget {
  const PlaybackTimesRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      PlaybackProgressCubit,
      PlaybackProgress,
      (String, String)
    >(
      selector: (progress) => (
        formatPlaybackTime(progress.position),
        '-${formatPlaybackTime(progress.remaining)}',
      ),
      builder: (context, times) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_TimeText(times.$1), _TimeText(times.$2)],
      ),
    );
  }
}

class _TimeText extends StatelessWidget {
  const _TimeText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return FixedSizeTimeText(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        fontSize: AppTextSizes.sm,
      ),
    );
  }
}

/// A time ("01:35", "01:35 / -02:40") in a box sized for its digit pattern.
///
/// Uses tabular (equal-width) digits and a box measured once per pattern, so
/// a ticking time only re-lays out itself, not the player around it. The box
/// only changes when the pattern does (e.g. 9:59 → 10:00).
class FixedSizeTimeText extends StatelessWidget {
  const FixedSizeTimeText(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  static final Map<Object, Size> _sizes = {};

  @override
  Widget build(BuildContext context) {
    final effective = DefaultTextStyle.of(context).style
        .merge(style)
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final scaler = MediaQuery.textScalerOf(context);
    final pattern = text.replaceAll(RegExp('[0-9]'), '0');
    final key = (pattern, effective, scaler);
    final size = _sizes[key] ??= _measure(pattern, effective, scaler);

    return RepaintBoundary(
      child: SizedBox.fromSize(
        size: size,
        child: Text(text, style: effective, maxLines: 1, softWrap: false),
      ),
    );
  }

  static Size _measure(String text, TextStyle style, TextScaler scaler) {
    if (_sizes.length > 64) _sizes.clear(); // patterns are few; stay small
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final size = Size(
      painter.width.ceilToDouble(),
      painter.height.ceilToDouble(),
    );
    painter.dispose();
    return size;
  }
}

/// ⏮: enabled when there's a previous song or the current one is past its
/// first 3 seconds (then it restarts the song). Rebuilds only when that
/// answer flips, not on every tick.
class PreviousButton extends StatelessWidget {
  const PreviousButton({super.key, this.iconSize});

  final double? iconSize;

  static const Duration restartThreshold = Duration(seconds: 3);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PlayerCubit, NowPlaying, bool>(
      selector: (state) => state.hasPrevious,
      builder: (context, hasPrevious) => hasPrevious
          ? _button(context, enabled: true)
          // No song before this one: ⏮ only restarts it, once it's past
          // its first seconds (the only case that follows the position).
          : BlocSelector<PlaybackProgressCubit, PlaybackProgress, bool>(
              selector: (progress) => progress.position > restartThreshold,
              builder: (context, canRestart) =>
                  _button(context, enabled: canRestart),
            ),
    );
  }

  Widget _button(BuildContext context, {required bool enabled}) {
    return IconButton(
      tooltip: AppStrings.previous,
      iconSize: iconSize,
      onPressed: enabled ? context.read<PlayerCubit>().previous : null,
      icon: const Icon(Icons.skip_previous_rounded),
    );
  }
}
