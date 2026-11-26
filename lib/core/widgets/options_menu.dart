import 'package:material_ui/material_ui.dart';

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/service/spacing.dart';

/// The ⋮ button with the app's compact options menu (songs, playlists).
class OptionsMenuButton<T> extends StatelessWidget {
  const OptionsMenuButton({
    super.key,
    required this.tooltip,
    required this.itemBuilder,
    required this.onSelected,
    this.padding = const EdgeInsets.all(8),
  });

  final String tooltip;
  final PopupMenuItemBuilder<T> itemBuilder;
  final PopupMenuItemSelected<T> onSelected;

  /// Around the icon; zero in dense rows.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: tooltip,
      icon: Icon(
        Icons.more_vert_rounded,
        size: 20.r,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      padding: padding,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      onSelected: onSelected,
      itemBuilder: itemBuilder,
    );
  }
}

/// One row of an [OptionsMenuButton]'s menu: icon and label, tinted with
/// [color] (e.g. the primary color for an active favourite, the error
/// color for delete), dimmed when disabled.
PopupMenuItem<T> optionsMenuItem<T>(
  BuildContext context, {
  required T value,
  required IconData icon,
  required String label,
  Color? color,
  bool enabled = true,
}) {
  final onSurface = Theme.of(context).colorScheme.onSurface;
  final tint = !enabled
      ? onSurface.withValues(alpha: 0.35)
      : color ?? onSurface;
  return PopupMenuItem<T>(
    value: value,
    enabled: enabled,
    height: 40.h,
    child: Row(
      children: [
        Icon(icon, size: 18.r, color: tint),
        horizontalSpace(12),
        // Long labels shrink instead of overflowing the menu's max width
        // (e.g. with large system font sizes).
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: tint, fontSize: AppTextSizes.sm),
          ),
        ),
      ],
    ),
  );
}
