import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';

/// A search history section's title (like the results' headers), with an
/// optional action at the end (e.g. "Clear").
class SearchHistoryHeader extends StatelessWidget {
  const SearchHistoryHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = actionLabel;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(20.w, 12.h, 8.w, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: AppTextSizes.lg,
                fontWeight: FontWeightHelper.bold,
              ),
            ),
          ),
          if (label != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: theme.primaryColor),
              child: Text(label),
            ),
        ],
      ),
    );
  }
}
