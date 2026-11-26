import 'package:material_ui/material_ui.dart';

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/service/spacing.dart';

/// Round check shown at the start of each row while selecting.
class SelectionCheck extends StatelessWidget {
  const SelectionCheck({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final size = 22.r;

    return Padding(
      padding: EdgeInsets.only(left: 8.w, right: 10.w),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? primary : Colors.transparent,
          border: Border.all(
            color: selected
                ? primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.35),
            width: 2,
          ),
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          scale: selected ? 1 : 0,
          child: Icon(
            Icons.check_rounded,
            size: size * 0.7,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// "✕  3 selected   Select all" — replaces the sort row while selecting.
class SelectionHeader extends StatelessWidget {
  const SelectionHeader({
    super.key,
    required this.count,
    required this.allSelected,
    required this.onClose,
    required this.onSelectAll,
    required this.onDeselectAll,
  });

  final int count;
  final bool allSelected;
  final VoidCallback onClose;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Row(
      children: [
        IconButton(
          tooltip: AppStrings.cancelSelection,
          onPressed: onClose,
          icon: Icon(Icons.close_rounded, color: onSurface),
        ),
        horizontalSpace(4),
        Expanded(
          child: Text(
            AppStrings.selectedCount(count),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: onSurface,
              fontSize: AppTextSizes.lg,
              fontWeight: FontWeightHelper.bold,
            ),
          ),
        ),
        TextButton(
          onPressed: allSelected ? onDeselectAll : onSelectAll,
          child: Text(
            allSelected ? AppStrings.deselectAll : AppStrings.selectAll,
            style: TextStyle(color: theme.primaryColor),
          ),
        ),
      ],
    );
  }
}

class BulkAction {
  const BulkAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
}

/// Floating bar of actions for the selected songs.
class BulkActionBar extends StatelessWidget {
  const BulkActionBar({
    super.key,
    required this.actions,
    required this.enabled,
  });

  final List<BulkAction> actions;

  /// False while nothing is selected.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark
          ? theme.colorScheme.surfaceContainerHigh
          : theme.colorScheme.surface,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(24.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        child: Row(
          children: [
            for (final action in actions)
              Expanded(
                child: Opacity(
                  opacity: enabled ? 1 : 0.4,
                  child: InkResponse(
                    onTap: enabled ? action.onTap : null,
                    radius: 36.r,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 6.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            action.icon,
                            size: 22.r,
                            color: action.destructive
                                ? theme.colorScheme.error
                                : onSurface,
                          ),
                          verticalSpace(4),
                          Text(
                            action.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: action.destructive
                                  ? theme.colorScheme.error
                                  : onSurface.withValues(alpha: 0.8),
                              fontSize: AppTextSizes.xs,
                              fontWeight: FontWeightHelper.medium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Asks before deleting [count] songs from the device. Returns true to go on.
Future<bool> confirmDeleteSongs(BuildContext context, int count) async {
  final error = Theme.of(context).colorScheme.error;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(Icons.delete_forever_rounded, color: error),
      title: Text(AppStrings.deleteSongsTitle(count)),
      content: const Text(AppStrings.deleteSongsMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text(AppStrings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(AppStrings.delete, style: TextStyle(color: error)),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
