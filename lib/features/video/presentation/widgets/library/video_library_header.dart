import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/video/presentation/logic/video_library_cubit.dart';
import 'package:melodix/features/video/presentation/widgets/library/scan_videos.dart';

/// "Videos", the count, and the scan button (a spinner while scanning).
class VideoLibraryHeader extends StatelessWidget {
  const VideoLibraryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 8.w, 4.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.videos,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: AppTextSizes.xxl,
                    fontWeight: FontWeightHelper.bold,
                  ),
                ),
                verticalSpace(2),
                BlocSelector<VideoLibraryCubit, VideoLibraryState, int>(
                  selector: (s) => s.videos.length,
                  builder: (context, count) => Text(
                    AppStrings.videosCount(count),
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.6),
                      fontSize: AppTextSizes.sm,
                    ),
                  ),
                ),
              ],
            ),
          ),
          BlocSelector<VideoLibraryCubit, VideoLibraryState, (bool, bool)>(
            selector: (s) =>
                (s.isScanning, s.status == VideoLibraryStatus.ready),
            builder: (context, scan) {
              final (scanning, ready) = scan;
              return IconButton(
                tooltip: AppStrings.scanVideos,
                onPressed: scanning || !ready
                    ? null
                    : () => scanVideos(context),
                icon: scanning
                    ? SizedBox.square(
                        dimension: 20.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.4,
                        ),
                      )
                    : const Icon(Icons.radar_rounded),
              );
            },
          ),
        ],
      ),
    );
  }
}
