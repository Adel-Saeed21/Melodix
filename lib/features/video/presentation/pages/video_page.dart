import 'package:material_ui/material_ui.dart';

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';

/// Video tab. Will list the videos stored on the device; shows an empty
/// state until local media loading is implemented.
class VideoPage extends StatelessWidget {
  const VideoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.video)),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.video_library_outlined,
                  size: 64.sp,
                  color: theme.primaryColor,
                ),
                verticalSpace(16),
                Text(
                  AppStrings.noVideosTitle,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: AppTextSizes.xl,
                    fontWeight: FontWeightHelper.bold,
                  ),
                ),
                verticalSpace(8),
                Text(
                  AppStrings.noVideosSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.6),
                    fontSize: AppTextSizes.base,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
