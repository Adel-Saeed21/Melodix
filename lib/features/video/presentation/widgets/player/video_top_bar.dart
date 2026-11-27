import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/features/subtitles/presentation/logic/subtitles_cubit.dart';
import 'package:melodix/features/subtitles/presentation/widgets/subtitles_sheet.dart';
import 'package:melodix/features/video/presentation/logic/video_player_cubit.dart';
import 'package:melodix/features/video/presentation/widgets/library/video_favourite_button.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_minimize_button.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_speed_button.dart';
import 'package:melodix/features/video/presentation/widgets/player/video_up_next_sheet.dart';
import 'package:melodix/features/video/presentation/widgets/video_tile.dart';

/// Minimize; the title, and where it is in the list with its quality
/// ("2 of 5 · 1080p"); Up next, subtitles, fill / fit, playback speed and
/// ♥.
class VideoTopBar extends StatelessWidget {
  const VideoTopBar({
    super.key,
    required this.onTouched,
    required this.fill,
    required this.onToggleFill,
  });

  final VoidCallback onTouched;

  /// The picture fills the screen (cropped) rather than fits in it.
  final bool fill;
  final VoidCallback onToggleFill;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoPlayerCubit, VideoPlayerState>(
      buildWhen: (p, c) =>
          p.video != c.video ||
          p.queue.length != c.queue.length ||
          p.index != c.index,
      builder: (context, state) {
        final video = state.video;
        final details = [
          if (state.queue.length > 1)
            context.l10n.videoPosition(state.index + 1, state.queue.length),
          VideoTile.qualityLabel(video.width, video.height, context.l10n),
        ].join(' · ');
        return Row(
          children: [
            const VideoMinimizeButton(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    video.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppTextSizes.base,
                      fontWeight: FontWeightHelper.semiBold,
                    ),
                  ),
                  Text(
                    details,
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: AppTextSizes.xs,
                    ),
                  ),
                ],
              ),
            ),
            if (state.queue.length > 1)
              IconButton(
                tooltip: context.l10n.upNext,
                color: Colors.white,
                onPressed: () {
                  onTouched();
                  showVideoUpNext(context);
                },
                icon: const Icon(Icons.video_library_rounded),
              ),
            BlocSelector<SubtitlesCubit, SubtitlesState, bool>(
              selector: (s) => s.isOn,
              builder: (context, on) => IconButton(
                tooltip: context.l10n.subtitles,
                color: Colors.white,
                onPressed: () {
                  onTouched();
                  showSubtitlesSheet(context, videoTitle: video.title);
                },
                icon: Icon(
                  on
                      ? Icons.closed_caption_rounded
                      : Icons.closed_caption_off_outlined,
                ),
              ),
            ),
            IconButton(
              tooltip: fill ? context.l10n.fitScreen : context.l10n.fillScreen,
              color: Colors.white,
              onPressed: () {
                onTouched();
                onToggleFill();
              },
              icon: Icon(
                fill ? Icons.fit_screen_rounded : Icons.crop_free_rounded,
              ),
            ),
            VideoSpeedButton(onTouched: onTouched),
            // Live: right even if changed elsewhere while this plays.
            VideoFavouriteButton(video: video, color: Colors.white),
          ],
        );
      },
    );
  }
}
