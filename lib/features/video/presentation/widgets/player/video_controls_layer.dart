import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_controls_shade.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_seek_bar.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_top_bar.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_transport_buttons.dart';
import 'package:video_player/video_player.dart';

/// The buttons over the video: top bar, previous / play / next, and the
/// seek bar with the rotate button.
class VideoControlsLayer extends StatelessWidget {
  const VideoControlsLayer({
    super.key,
    required this.controller,
    required this.onRotate,
    required this.onTouched,
    required this.onDragging,
  });

  final VideoPlayerController controller;
  final VoidCallback onRotate;

  /// Any button pressed: keep the controls up a little longer.
  final VoidCallback onTouched;
  final ValueChanged<bool> onDragging;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VideoPlayerCubit>();
    final padding = MediaQuery.paddingOf(context);
    // Taps between the buttons reach the video (show / hide, double-tap):
    // the shading takes no touches.
    return Stack(
      fit: StackFit.expand,
      children: [
        const VideoControlsShade(),
        Padding(
          padding: EdgeInsets.fromLTRB(
            padding.left + 4.w,
            padding.top + 4.h,
            padding.right + 4.w,
            padding.bottom + 8.h,
          ),
          child: Column(
            children: [
              VideoTopBar(onTouched: onTouched),
              const Spacer(),
              VideoTransportButtons(
                controller: controller,
                onTouched: onTouched,
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: VideoSeekBar(
                      controller: controller,
                      onSeek: cubit.seek,
                      onDragging: onDragging,
                    ),
                  ),
                  IconButton(
                    tooltip: AppStrings.rotateScreen,
                    color: Colors.white,
                    onPressed: () {
                      onTouched();
                      onRotate();
                    },
                    icon: const Icon(Icons.screen_rotation_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
