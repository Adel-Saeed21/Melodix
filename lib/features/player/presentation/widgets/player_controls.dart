import 'package:material_ui/material_ui.dart';

import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/features/player/presentation/utils/player_rebuild_stats.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';

/// A progress bar the user can drag to seek. While dragging it shows the
/// drag position and only seeks when released.
class SeekBar extends StatefulWidget {
  const SeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.compact = false,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  /// Thinner track and smaller thumb, for the mini player.
  final bool compact;

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    // ignore: invalid_use_of_visible_for_testing_member
    PlayerRebuildStats.hit('seekBar');
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final max = widget.duration.inMilliseconds.toDouble();
    final enabled = max > 0;
    final value = enabled
        ? (_dragValue ?? widget.position.inMilliseconds.toDouble()).clamp(
            0.0,
            max,
          )
        : 0.0;

    // Moves on every position tick: its own layer keeps that off the rest.
    return RepaintBoundary(
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: widget.compact ? 2.5 : 3.5,
          activeTrackColor: onSurface.withValues(alpha: 0.9),
          inactiveTrackColor: onSurface.withValues(alpha: 0.2),
          thumbColor: onSurface,
          overlayColor: onSurface.withValues(alpha: 0.1),
          thumbShape: RoundSliderThumbShape(
            enabledThumbRadius: widget.compact ? 5 : 7,
          ),
          overlayShape: RoundSliderOverlayShape(
            overlayRadius: widget.compact ? 12 : 18,
          ),
          trackShape: const RoundedRectSliderTrackShape(),
          padding: EdgeInsets.zero,
        ),
        child: Slider(
          value: value,
          max: enabled ? max : 1,
          onChanged: enabled ? (v) => setState(() => _dragValue = v) : null,
          onChangeEnd: enabled
              ? (v) {
                  widget.onSeek(Duration(milliseconds: v.round()));
                  setState(() => _dragValue = null);
                }
              : null,
          semanticFormatterCallback: (v) =>
              '${(v / 1000).round()} ${AppStrings.secondsShort}',
        ),
      ),
    );
  }
}

/// Green round play / pause button (shows replay after the queue ended and
/// a spinner while loading).
class PlayPauseButton extends StatelessWidget {
  const PlayPauseButton({
    super.key,
    required this.isPlaying,
    required this.isLoading,
    required this.isCompleted,
    required this.onPressed,
    required this.size,
  });

  /// Shows ⏸ (else ▶).
  final bool isPlaying;

  /// Shows a spinner while not playing yet.
  final bool isLoading;

  /// The queue ended: shows ↻ (play again).
  final bool isCompleted;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final icon = isPlaying
        ? Icons.pause_rounded
        : isCompleted
        ? Icons.replay_rounded
        : Icons.play_arrow_rounded;

    return Semantics(
      button: true,
      label: isPlaying ? AppStrings.pause : AppStrings.play,
      excludeSemantics: true,
      child: Tooltip(
        message: isPlaying ? AppStrings.pause : AppStrings.play,
        child: Material(
          color: primary,
          shape: const CircleBorder(),
          elevation: 2,
          shadowColor: primary.withValues(alpha: 0.5),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: size,
              child: isLoading && !isPlaying
                  ? Padding(
                      padding: EdgeInsets.all(size * 0.28),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Icon(icon, color: Colors.white, size: size * 0.55),
            ),
          ),
        ),
      ),
    );
  }
}

/// Repeat toggle: off (dim) → all (green) → one (green, "1").
class RepeatButton extends StatelessWidget {
  const RepeatButton({
    super.key,
    required this.mode,
    required this.onPressed,
    this.size = 22,
  });

  final PlaybackRepeat mode;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = mode != PlaybackRepeat.off;
    return IconButton(
      tooltip: switch (mode) {
        PlaybackRepeat.off => AppStrings.repeatOff,
        PlaybackRepeat.all => AppStrings.repeatAll,
        PlaybackRepeat.one => AppStrings.repeatOne,
      },
      onPressed: onPressed,
      icon: Icon(
        mode == PlaybackRepeat.one
            ? Icons.repeat_one_rounded
            : Icons.repeat_rounded,
        size: size,
        color: active
            ? theme.primaryColor
            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }
}
