import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:melodix/features/video/presentation/playback/video_engine.dart';
import 'package:melodix/features/video/presentation/widgets/player/engine_selector.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_round_button.dart';

/// Previous, back, play / pause (replay at the end), forward, next. The
/// back / forward jump is the user's choice in Settings (10 s by default).
class VideoTransportButtons extends StatelessWidget {
  const VideoTransportButtons({
    super.key,
    required this.engine,
    required this.onTouched,
  });

  final VideoEngine engine;

  /// Any button pressed: keep the controls up a little longer.
  final VoidCallback onTouched;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VideoPlayerCubit>();
    final jump = videoSeekStepOf(context);
    final seconds = jump.inSeconds;
    VoidCallback tap(VoidCallback action) => () {
      onTouched();
      action();
    };
    return BlocBuilder<VideoPlayerCubit, VideoPlayerState>(
      buildWhen: (p, c) =>
          p.hasNext != c.hasNext || p.hasPrevious != c.hasPrevious,
      builder: (context, state) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          VideoRoundButton(
            icon: Icons.skip_previous_rounded,
            tooltip: context.l10n.previousVideo,
            size: 44.r,
            onPressed: tap(cubit.previous),
          ),
          SizedBox(width: 12.w),
          VideoRoundButton(
            icon: _backIcon(seconds),
            tooltip: context.l10n.backSeconds(seconds),
            size: 48.r,
            onPressed: tap(() => cubit.seekBy(-jump)),
          ),
          SizedBox(width: 16.w),
          EngineSelector<(bool, bool)>(
            engine: engine,
            select: (v) => (v.isPlaying, v.isCompleted),
            builder: (context, playback) {
              final (playing, completed) = playback;
              return VideoRoundButton(
                icon: completed
                    ? Icons.replay_rounded
                    : playing
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                tooltip: completed
                    ? context.l10n.replay
                    : playing
                    ? context.l10n.pause
                    : context.l10n.play,
                size: 72.r,
                filled: true,
                // Frosted only on a still picture (see VideoRoundButton).
                frosted: !playing,
                onPressed: tap(cubit.togglePlayPause),
              );
            },
          ),
          SizedBox(width: 16.w),
          VideoRoundButton(
            icon: _forwardIcon(seconds),
            tooltip: context.l10n.forwardSeconds(seconds),
            size: 48.r,
            onPressed: tap(() => cubit.seekBy(jump)),
          ),
          SizedBox(width: 12.w),
          VideoRoundButton(
            icon: Icons.skip_next_rounded,
            tooltip: context.l10n.nextVideo,
            size: 44.r,
            onPressed: state.hasNext ? tap(cubit.next) : null,
          ),
        ],
      ),
    );
  }

  static IconData _backIcon(int seconds) => switch (seconds) {
    5 => Icons.replay_5_rounded,
    10 => Icons.replay_10_rounded,
    30 => Icons.replay_30_rounded,
    _ => Icons.fast_rewind_rounded,
  };

  static IconData _forwardIcon(int seconds) => switch (seconds) {
    5 => Icons.forward_5_rounded,
    10 => Icons.forward_10_rounded,
    30 => Icons.forward_30_rounded,
    _ => Icons.fast_forward_rounded,
  };
}

/// The skip jump the user chose in Settings (10 s without preferences
/// above, e.g. in tests).
Duration videoSeekStepOf(BuildContext context) =>
    UiPreferencesScope.of(context).videoSeekStep;
