import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/music_library/presentation/utils/duration_format.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/presentation/widgets/video_thumbnail.dart';

/// A video row: thumbnail (with its length), title, and a details line
/// (quality, or where to resume). One line of title, so every row has the
/// same height (lists can be fixed-height: fast to scroll and to jump in).
class VideoTile extends StatelessWidget {
  const VideoTile({super.key, required this.video, this.onTap, this.trailing});

  final Video video;

  /// Null: the row isn't tappable (e.g. no player to open it yet).
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20.w,
          8.h,
          trailing == null ? 20.w : 4.w,
          8.h,
        ),
        child: Row(
          children: [
            VideoThumbnail(video: video, width: 112.r),
            horizontalSpace(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: onSurface,
                      fontSize: AppTextSizes.base,
                      fontWeight: FontWeightHelper.semiBold,
                    ),
                  ),
                  verticalSpace(3),
                  Text(
                    _details(video),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.6),
                      fontSize: AppTextSizes.sm,
                    ),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  /// "Resume at 3:12" for a video started but not finished, else its
  /// quality ("1080p", "4K").
  static String _details(Video video) {
    if (video.lastPosition > Duration.zero) {
      return AppStrings.resumeAt(formatDuration(video.lastPosition));
    }
    return qualityLabel(video.width, video.height);
  }

  /// "4K", "1080p", "720p"… from the shorter side (so portrait videos read
  /// the same as landscape ones).
  static String qualityLabel(int width, int height) {
    final short = width < height ? width : height;
    if (short <= 0) return AppStrings.video;
    if (short >= 2160) return '4K';
    return '${short}p';
  }
}
