import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';

/// A ranked row: number, (picture), name, plays and a bar against the
/// most played.
class StatsRankRow extends StatelessWidget {
  const StatsRankRow({
    super.key,
    required this.rank,
    required this.title,
    required this.plays,
    required this.most,
    this.subtitle,
    this.leading,
  });

  final int rank;
  final String title;
  final String? subtitle;
  final int plays;
  final int most;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          SizedBox(
            width: 22.w,
            child: Text(
              '$rank',
              style: TextStyle(
                color: rank == 1
                    ? theme.primaryColor
                    : onSurface.withValues(alpha: 0.5),
                fontSize: AppTextSizes.lg,
                fontWeight: FontWeightHelper.bold,
              ),
            ),
          ),
          if (leading case final leading?) ...[leading, SizedBox(width: 12.w)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: onSurface,
                    fontWeight: FontWeightHelper.semiBold,
                  ),
                ),
                if (subtitle case final subtitle?)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.6),
                      fontSize: AppTextSizes.sm,
                    ),
                  ),
                SizedBox(height: 6.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: most == 0 ? 0 : plays / most,
                    minHeight: 4,
                    color: theme.primaryColor,
                    backgroundColor: onSurface.withValues(alpha: 0.08),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            AppStrings.statsTimes(plays),
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
