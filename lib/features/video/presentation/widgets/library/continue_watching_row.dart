import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/core/utils/duration_format.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/domain/entities/video_progress.dart';
import 'package:melodix/features/video/presentation/widgets/video_thumbnail.dart';

/// Videos started but not finished, side by side, each resuming where it
/// stopped: a large thumbnail with a play button, the time left and a
/// progress bar, then the title and where it resumes.
class ContinueWatchingRow extends StatelessWidget {
  const ContinueWatchingRow({
    super.key,
    required this.videos,
    required this.progress,
    required this.onOpen,
  });

  final List<Video> videos;
  final Map<String, VideoProgress> progress;
  final void Function(List<Video> videos, int index) onOpen;

  @override
  Widget build(BuildContext context) {
    final cardWidth = 220.r;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
          child: Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 20.r,
                color: Theme.of(context).primaryColor,
              ),
              horizontalSpace(8),
              Text(
                AppStrings.continueWatching,
                style: TextStyle(
                  color: onSurface,
                  fontSize: AppTextSizes.lg,
                  fontWeight: FontWeightHelper.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          // Thumbnail + two lines of text (grows with the text size).
          height:
              cardWidth * 9 / 16 +
              56 * MediaQuery.textScalerOf(context).scale(1),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            itemCount: videos.length,
            separatorBuilder: (_, _) => horizontalSpace(14),
            itemBuilder: (context, index) => _ContinueCard(
              video: videos[index],
              progress: progress[videos[index].id],
              width: cardWidth,
              onTap: () => onOpen(videos, index),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.video,
    required this.progress,
    required this.width,
    required this.onTap,
  });

  final Video video;
  final VideoProgress? progress;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.primaryColor;
    final position = progress?.position ?? Duration.zero;
    final left = video.duration - position;
    final fraction = progress?.fraction(video.duration) ?? 0;
    final radius = BorderRadius.circular(14.r);
    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: radius,
              child: SizedBox(
                width: width,
                height: width * 9 / 16,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    VideoThumbnail(
                      video: video,
                      width: width,
                      showDuration: false,
                    ),
                    // Darker towards the bottom, so the labels read on any
                    // picture.
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xB3000000)],
                          stops: [0.45, 1],
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 44.r,
                        height: 44.r,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.85),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 28.r,
                        ),
                      ),
                    ),
                    if (left > Duration.zero)
                      Positioned(
                        right: 8.r,
                        bottom: 10.r,
                        child: Text(
                          AppStrings.timeLeft(formatDuration(left)),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppTextSizes.xs,
                            fontWeight: FontWeightHelper.semiBold,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            verticalSpace(8),
            Text(
              video.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: onSurface,
                fontSize: AppTextSizes.sm,
                fontWeight: FontWeightHelper.semiBold,
              ),
            ),
            verticalSpace(2),
            Text(
              AppStrings.resumeAt(formatDuration(position)),
              maxLines: 1,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.6),
                fontSize: AppTextSizes.xs,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
