import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/theme/app_colors.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/widgets/app_snack_bar.dart';

class SnackBarCard extends StatelessWidget {
  const SnackBarCard({
    super.key,
    required this.message,
    required this.kind,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final AppSnackBarKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final accent = switch (kind) {
      AppSnackBarKind.success => Theme.of(context).primaryColor,
      AppSnackBarKind.error => theme.colorScheme.error,
    };
    // The nav bar's glass, a little denser so text stays readable over
    // busy covers.
    final glass =
        (isDark
                ? AppColors.navigationBarDarkBackground
                : theme.colorScheme.surface)
            .withValues(alpha: isDark ? 0.85 : 0.9);
    final radius = BorderRadius.circular(20.r);
    final label = actionLabel;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              10.w,
              10.h,
              label == null ? 16.w : 8.w,
              10.h,
            ),
            decoration: BoxDecoration(
              color: glass,
              borderRadius: radius,
              border: Border.all(
                color: onSurface.withValues(alpha: isDark ? 0.12 : 0.08),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32.r,
                  height: 32.r,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    kind == AppSnackBarKind.success
                        ? Icons.check_rounded
                        : Icons.error_outline_rounded,
                    size: 18.r,
                    color: accent,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: onSurface,
                      fontSize: AppTextSizes.base,
                      fontWeight: FontWeightHelper.semiBold,
                    ),
                  ),
                ),
                if (label != null) ...[
                  SizedBox(width: 8.w),
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      backgroundColor: Theme.of(context).primaryColor
                          .withValues(alpha: 0.14),
                      shape: const StadiumBorder(),
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      minimumSize: Size(0, 36.h),
                      tapTargetSize: MaterialTapTargetSize.padded,
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: AppTextSizes.base,
                        fontWeight: FontWeightHelper.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
