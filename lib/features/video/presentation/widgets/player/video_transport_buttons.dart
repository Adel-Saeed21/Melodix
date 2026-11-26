import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:melodix/features/video/presentation/widgets/player/controller_selector.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_round_button.dart';
import 'package:video_player/video_player.dart';

/// Previous, play / pause (replay at the end) and next.
class VideoTransportButtons extends StatelessWidget {
  const VideoTransportButtons({
    super.key,
    required this.controller,
    required this.onTouched,
  });

  final VideoPlayerController controller;

  /// Any button pressed: keep the controls up a little longer.
  final VoidCallback onTouched;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VideoPlayerCubit>();
    return BlocBuilder<VideoPlayerCubit, VideoPlayerState>(
      buildWhen: (p, c) =>
          p.hasNext != c.hasNext || p.hasPrevious != c.hasPrevious,
      builder: (context, state) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          VideoRoundButton(
            icon: Icons.skip_previous_rounded,
            tooltip: AppStrings.previousVideo,
            size: 48.r,
            onPressed: () {
              onTouched();
              cubit.previous();
            },
          ),
          SizedBox(width: 28.w),
          ControllerSelector<(bool, bool)>(
            controller: controller,
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
                    ? AppStrings.replay
                    : playing
                    ? AppStrings.pause
                    : AppStrings.play,
                size: 68.r,
                filled: true,
                onPressed: () {
                  onTouched();
                  cubit.togglePlayPause();
                },
              );
            },
          ),
          SizedBox(width: 28.w),
          VideoRoundButton(
            icon: Icons.skip_next_rounded,
            tooltip: AppStrings.nextVideo,
            size: 48.r,
            onPressed: state.hasNext
                ? () {
                    onTouched();
                    cubit.next();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
