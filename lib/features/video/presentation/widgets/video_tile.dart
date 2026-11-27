import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/core/utils/duration_format.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/domain/entities/video_progress.dart';
import 'package:melodix/features/video/presentation/widgets/video_thumbnail.dart';

/// A video row: thumbnail (with its length), title, and a details line
/// (quality, or where to resume). One line of title, so every row has the
/// same height (lists can be fixed-height: fast to scroll and to jump in).
class VideoTile extends StatelessWidget {
  const VideoTile({
    super.key,
    required this.video,
    this.progress,
    this.onTap,
    this.onLongPress,
    this.leading,
    this.trailing,
  });

  final Video video;

  /// How much was watched, if it was played ("Resume at …", a bar).
  final VideoProgress? progress;

  /// Null: the row isn't tappable.
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Before the thumbnail (e.g. a check while selecting).
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          20.w,
          8.h,
          trailing == null ? 20.w : 4.w,
          8.h,
        ),
        child: Row(
          children: [
            ?leading,
            VideoThumbnail(video: video, progress: progress, width: 112.r),
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
                    _details(video, progress, context.l10n),
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
  static String _details(
    Video video,
    VideoProgress? progress,
    AppLocalizations l10n,
  ) {
    if (progress != null && progress.canResume(video.duration)) {
      return l10n.resumeAt(formatDuration(progress.position));
    }
    return qualityLabel(video.width, video.height, l10n);
  }

  /// "4K", "1080p", "720p"… from the shorter side (so portrait videos read
  /// the same as landscape ones).
  static String qualityLabel(int width, int height, AppLocalizations l10n) {
    final short = width < height ? width : height;
    if (short <= 0) return l10n.video;
    if (short >= 2160) return '4K';
    return '${short}p';
  }
}
