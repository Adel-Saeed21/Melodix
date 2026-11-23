import 'package:material_ui/material_ui.dart';

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';

class LibraryStatusView extends StatelessWidget {
  const LibraryStatusView({
    super.key,
    this.icon,
    this.showProgress = false,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData? icon;

  final bool showProgress;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showProgress)
              SizedBox.square(
                dimension: 48.r,
                child: CircularProgressIndicator(
                  color: theme.primaryColor,
                  strokeWidth: 3,
                ),
              )
            else if (icon != null)
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40.r, color: theme.primaryColor),
              ),
            verticalSpace(20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onSurface,
                fontSize: AppTextSizes.xl,
                fontWeight: FontWeightHelper.bold,
              ),
            ),
            verticalSpace(8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.6),
                fontSize: AppTextSizes.base,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              verticalSpace(24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 32.w,
                    vertical: 14.h,
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
