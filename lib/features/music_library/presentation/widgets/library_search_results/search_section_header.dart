import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';

class SearchSectionHeader extends StatelessWidget {
  const SearchSectionHeader({
    super.key,
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 4.h),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: onSurface,
              fontSize: AppTextSizes.lg,
              fontWeight: FontWeightHelper.bold,
            ),
          ),
          horizontalSpace(8),
          Text(
            '$count',
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.5),
              fontSize: AppTextSizes.sm,
            ),
          ),
        ],
      ),
    );
  }
}
