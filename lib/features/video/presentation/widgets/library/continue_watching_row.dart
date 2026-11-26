import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/music_library/presentation/utils/duration_format.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/presentation/widgets/video_thumbnail.dart';

/// Videos started but not finished, side by side, each resuming where it
/// stopped.
class ContinueWatchingRow extends StatelessWidget {
  const ContinueWatchingRow({
    super.key,
    required this.videos,
    required this.onOpen,
  });

  final List<Video> videos;
  final void Function(List<Video> videos, int index) onOpen;

  @override
  Widget build(BuildContext context) {
    final cardWidth = 176.r;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 10.h),
          child: Text(
            AppStrings.continueWatching,
            style: TextStyle(
              color: onSurface,
              fontSize: AppTextSizes.lg,
              fontWeight: FontWeightHelper.bold,
            ),
          ),
        ),
        SizedBox(
          // Thumbnail + two lines of text (grows with the text size).
          height:
              cardWidth * 9 / 16 +
              52 * MediaQuery.textScalerOf(context).scale(1),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            itemCount: videos.length,
            separatorBuilder: (_, _) => horizontalSpace(12),
            itemBuilder: (context, index) {
              final video = videos[index];
              return SizedBox(
                width: cardWidth,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10.r),
                  onTap: () => onOpen(videos, index),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VideoThumbnail(video: video, width: cardWidth),
                      verticalSpace(6),
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
                      Text(
                        AppStrings.resumeAt(formatDuration(video.lastPosition)),
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
            },
          ),
        ),
      ],
    );
  }
}
