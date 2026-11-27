import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';

/// A recent search: tap to search it again, ✕ to forget it.
class RecentSearchRow extends StatelessWidget {
  const RecentSearchRow({
    super.key,
    required this.query,
    required this.onTap,
    required this.onRemove,
  });

  final String query;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return ListTile(
      contentPadding: EdgeInsets.only(left: 20.w, right: 8.w),
      leading: Icon(
        Icons.history_rounded,
        color: onSurface.withValues(alpha: 0.55),
      ),
      title: Text(
        query,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: onSurface, fontSize: AppTextSizes.base),
      ),
      trailing: IconButton(
        tooltip: AppStrings.removeRecentSearch,
        icon: Icon(
          Icons.close_rounded,
          size: 20.r,
          color: onSurface.withValues(alpha: 0.55),
        ),
        onPressed: onRemove,
      ),
      onTap: onTap,
    );
  }
}
