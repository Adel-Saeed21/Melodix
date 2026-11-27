import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:melodix/features/video/presentation/widgets/player/audio_mode/audio_mode_button.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_controls_shade.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_seek_bar.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_top_bar.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_transport_buttons.dart';
import 'package:melodix/features/video/presentation/playback/video_engine.dart';

/// The buttons over the video: the top bar, the transport buttons, and
/// the seek bar between lock and listen-as-audio / rotate.
class VideoControlsLayer extends StatelessWidget {
  const VideoControlsLayer({
    super.key,
    required this.engine,
    required this.onRotate,
    required this.onTouched,
    required this.onDragging,
    required this.fill,
    required this.onToggleFill,
    required this.onLock,
  });

  final VideoEngine engine;
  final VoidCallback onRotate;

  /// Any button pressed: keep the controls up a little longer.
  final VoidCallback onTouched;
  final ValueChanged<bool> onDragging;
  final bool fill;
  final VoidCallback onToggleFill;

  /// Locks the screen against touches (only Unlock works then).
  final VoidCallback onLock;

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
              VideoTopBar(
                onTouched: onTouched,
                fill: fill,
                onToggleFill: onToggleFill,
              ),
              const Spacer(),
              VideoTransportButtons(engine: engine, onTouched: onTouched),
              const Spacer(),
              Row(
                children: [
                  IconButton(
                    tooltip: context.l10n.lockControls,
                    color: Colors.white,
                    onPressed: onLock,
                    icon: const Icon(Icons.lock_outline_rounded),
                  ),
                  Expanded(
                    child: VideoSeekBar(
                      engine: engine,
                      onSeek: cubit.seek,
                      onDragging: onDragging,
                    ),
                  ),
                  AudioModeButton(onTouched: onTouched),
                  IconButton(
                    tooltip: context.l10n.rotateScreen,
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
