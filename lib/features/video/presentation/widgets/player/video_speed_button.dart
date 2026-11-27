import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_player_controls.dart';

/// The playback speed ("1.5x"); a tap lists the others.
class VideoSpeedButton extends StatelessWidget {
  const VideoSpeedButton({super.key, this.onTouched});

  /// Opened: keep the controls up a little longer.
  final VoidCallback? onTouched;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VideoPlayerCubit>();
    return BlocSelector<VideoPlayerCubit, VideoPlayerState, double>(
      selector: (s) => s.speed,
      builder: (context, speed) => PopupMenuButton<double>(
        tooltip: context.l10n.playbackSpeed,
        initialValue: speed,
        onOpened: onTouched,
        onSelected: cubit.setSpeed,
        itemBuilder: (_) => [
          for (final s in VideoPlayerControls.speeds)
            PopupMenuItem(value: s, child: Text(label(s))),
        ],
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          child: Text(
            label(speed),
            style: TextStyle(
              color: Colors.white,
              fontSize: AppTextSizes.sm,
              fontWeight: FontWeightHelper.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// 1x, 1.5x, 0.75x.
  static String label(double speed) {
    final text = speed == speed.roundToDouble()
        ? speed.toStringAsFixed(0)
        : speed.toString();
    return '${text}x';
  }
}
