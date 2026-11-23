import 'package:material_ui/material_ui.dart';

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/features/music_library/domain/entities/song_sort_order.dart';

/// A compact "⇅ Recently added ▾" chip that opens the sort options.
class SongSortButton extends StatelessWidget {
  const SongSortButton({
    super.key,
    required this.order,
    required this.onSelected,
  });

  final SongSortOrder order;
  final ValueChanged<SongSortOrder> onSelected;

  static String label(SongSortOrder order) {
    switch (order) {
      case SongSortOrder.recentlyAdded:
        return AppStrings.recentlyAdded;
      case SongSortOrder.title:
        return AppStrings.aToZ;
      case SongSortOrder.mostPlayed:
        return AppStrings.mostPlayed;
    }
  }

  static IconData icon(SongSortOrder order) {
    switch (order) {
      case SongSortOrder.recentlyAdded:
        return Icons.schedule_rounded;
      case SongSortOrder.title:
        return Icons.sort_by_alpha_rounded;
      case SongSortOrder.mostPlayed:
        return Icons.trending_up_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.primaryColor;

    return PopupMenuButton<SongSortOrder>(
      tooltip: AppStrings.sortBy,
      initialValue: order,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final option in SongSortOrder.values)
          PopupMenuItem(
            value: option,
            height: 40.h,
            child: Row(
              children: [
                Icon(
                  icon(option),
                  size: 18.r,
                  color: option == order ? primary : onSurface,
                ),
                horizontalSpace(12),
                Expanded(
                  child: Text(
                    label(option),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: option == order ? primary : onSurface,
                      fontSize: AppTextSizes.sm,
                      fontWeight: option == order
                          ? FontWeightHelper.semiBold
                          : FontWeightHelper.regular,
                    ),
                  ),
                ),
                if (option == order)
                  Icon(Icons.check_rounded, size: 18.r, color: primary),
              ],
            ),
          ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: onSurface.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_vert_rounded, size: 16.r, color: primary),
            horizontalSpace(6),
            // Shrinks with "…" instead of overflowing at large text sizes.
            Flexible(
              child: Text(
                label(order),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: onSurface,
                  fontSize: AppTextSizes.sm,
                  fontWeight: FontWeightHelper.medium,
                ),
              ),
            ),
            horizontalSpace(2),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 20.r,
              color: onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
