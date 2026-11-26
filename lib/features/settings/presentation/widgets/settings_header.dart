import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';

/// The top of Settings: the title and a line under it, like the Music and
/// Video tabs' headers.
class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 12.h, 4.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.settings,
            style: TextStyle(
              color: onSurface,
              fontSize: AppTextSizes.xxl,
              fontWeight: FontWeightHelper.bold,
            ),
          ),
          verticalSpace(2),
          Text(
            AppStrings.settingsTagline,
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.6),
              fontSize: AppTextSizes.sm,
            ),
          ),
        ],
      ),
    );
  }
}
