import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_minimize_button.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';

/// Why the video can't play, with a way on: try again, or the next one.
class VideoPlaybackErrorView extends StatelessWidget {
  const VideoPlaybackErrorView({super.key, required this.state});

  final VideoPlayerState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VideoPlayerCubit>();
    final missing = state.error == VideoPlayerError.missing;
    return SafeArea(
      child: Stack(
        children: [
          const Align(
            alignment: Alignment.topLeft,
            child: VideoMinimizeButton(),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    missing
                        ? Icons.videocam_off_rounded
                        : Icons.error_outline_rounded,
                    color: Colors.white70,
                    size: 56.r,
                  ),
                  verticalSpace(16),
                  Text(
                    missing
                        ? AppStrings.videoMissing
                        : AppStrings.videoUnplayable,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppTextSizes.lg,
                      fontWeight: FontWeightHelper.bold,
                    ),
                  ),
                  verticalSpace(4),
                  Text(
                    state.video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: AppTextSizes.sm,
                    ),
                  ),
                  verticalSpace(24),
                  Wrap(
                    spacing: 12.w,
                    runSpacing: 8.h,
                    alignment: WrapAlignment.center,
                    children: [
                      if (!missing)
                        OutlinedButton(
                          onPressed: cubit.retry,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                          child: const Text(AppStrings.tryAgain),
                        ),
                      if (state.hasNext)
                        FilledButton.icon(
                          onPressed: cubit.next,
                          icon: const Icon(Icons.skip_next_rounded),
                          label: const Text(AppStrings.nextVideo),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
