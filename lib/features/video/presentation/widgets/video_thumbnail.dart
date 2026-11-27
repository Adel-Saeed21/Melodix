import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/widgets/media_image.dart';
import 'package:melodix/core/utils/duration_format.dart';
import 'package:melodix/features/video/domain/entities/video.dart';
import 'package:melodix/features/video/domain/entities/video_progress.dart';
import 'package:melodix/features/video/domain/usecases/get_video_thumbnail_usecase.dart';

/// A video's thumbnail (16:9 by default) with its length in a corner.
/// Loads like song covers do (see [MediaImage]): cached ones show at once,
/// and fast flings don't ask the device for every row they pass.
class VideoThumbnail extends StatelessWidget {
  const VideoThumbnail({
    super.key,
    required this.video,
    required this.width,
    this.progress,
    this.showDuration = true,
  });

  final Video video;
  final double width;
  final bool showDuration;

  /// Shown as a thin bar along the bottom while the video can be resumed.
  final VideoProgress? progress;

  @override
  Widget build(BuildContext context) {
    final thumbnails = getIt<GetVideoThumbnailUseCase>();
    final height = width * 9 / 16;
    final radius = BorderRadius.circular(10.r);
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MediaImage(
            mediaKey: video.id,
            width: width,
            height: height,
            load: (pixels) => thumbnails(video.id, size: pixels),
            cached: (pixels) => thumbnails.cached(video.id, size: pixels),
            borderRadius: radius,
            placeholderIcon: Icons.movie_rounded,
          ),
          if (showDuration && video.duration > Duration.zero)
            PositionedDirectional(
              end: 4.r,
              bottom: 4.r,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.r, vertical: 1),
                  child: Text(
                    formatDuration(video.duration),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppTextSizes.xs,
                      fontWeight: FontWeightHelper.semiBold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
          if (progress != null && progress!.canResume(video.duration))
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(10.r),
                ),
                child: LinearProgressIndicator(
                  value: progress!.fraction(video.duration),
                  minHeight: 3,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
