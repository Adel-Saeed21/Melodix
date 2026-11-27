import 'dart:ui' show ImageFilter;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:melodix/features/video/presentation/playback/video_engine.dart';
import 'package:melodix/features/video/presentation/widgets/library/video_favourite_button.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_minimize_button.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_seek_bar.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_speed_button.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_transport_buttons.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_up_next_sheet.dart';
import 'package:melodix/features/video/presentation/widgets/video_thumbnail.dart';

/// The full player while the video is listened to as audio: like the
/// music's now playing (its thumbnail as the cover, over a blurred copy
/// of it), with the same seek bar and buttons as the video, and a way
/// back to watching it.
///
/// Nothing draws the picture here, so the screen can sleep and the sound
/// goes on.
class VideoAudioView extends StatelessWidget {
  const VideoAudioView({super.key, required this.engine});

  final VideoEngine engine;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VideoPlayerCubit>();
    return BlocBuilder<VideoPlayerCubit, VideoPlayerState>(
      buildWhen: (p, c) =>
          p.video != c.video ||
          p.index != c.index ||
          p.queue.length != c.queue.length,
      builder: (context, state) {
        final video = state.video;
        return LayoutBuilder(
          builder: (context, constraints) {
            final coverWidth = (constraints.maxWidth - 48.w).clamp(
              0.0,
              // 16:9, at most about 40% of the height.
              constraints.maxHeight * 0.4 * 16 / 9,
            );
            return Stack(
              fit: StackFit.expand,
              children: [
                // The thumbnail, blurred and darkened, behind it all.
                ExcludeSemantics(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                    child: FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: VideoThumbnail(
                        video: video,
                        width: constraints.maxWidth,
                        showDuration: false,
                      ),
                    ),
                  ),
                ),
                ColoredBox(color: Colors.black.withValues(alpha: 0.55)),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const VideoMinimizeButton(),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.headphones_rounded,
                                    color: Colors.white70,
                                    size: 18.r,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    context.l10n.audioOnlyMode,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: AppTextSizes.sm,
                                      fontWeight: FontWeightHelper.semiBold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const VideoSpeedButton(),
                          ],
                        ),
                        const Spacer(),
                        VideoThumbnail(
                          video: video,
                          width: coverWidth,
                          showDuration: false,
                        ),
                        SizedBox(height: 28.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      video.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: AppTextSizes.lg,
                                        fontWeight: FontWeightHelper.bold,
                                      ),
                                    ),
                                    if (state.queue.length > 1)
                                      Text(
                                        context.l10n.videoPosition(
                                          state.index + 1,
                                          state.queue.length,
                                        ),
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: AppTextSizes.sm,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Live: right even if changed elsewhere.
                              VideoFavouriteButton(
                                video: video,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: VideoSeekBar(
                            engine: engine,
                            onSeek: cubit.seek,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        VideoTransportButtons(engine: engine, onTouched: () {}),
                        const Spacer(),
                        Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed: () => cubit.setAudioOnly(false),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.16,
                                  ),
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.ondemand_video_rounded),
                                label: Text(context.l10n.watchVideo),
                              ),
                              if (state.queue.length > 1) ...[
                                SizedBox(width: 8.w),
                                IconButton(
                                  tooltip: context.l10n.upNext,
                                  color: Colors.white,
                                  onPressed: () => showVideoUpNext(context),
                                  icon: const Icon(Icons.video_library_rounded),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
