import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/theme/app_colors.dart';
import 'package:melodix/features/navigation/presentation/widgets/glass_nav_bar.dart';
import 'package:melodix/features/navigation/presentation/widgets/glass_nav_bar/glass_nav_item_button.dart';

class GlassBar extends StatelessWidget {
  const GlassBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.vertical,
  });

  final List<GlassNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    final glassColor =
        (isDark
                ? AppColors.navigationBarDarkBackground
                : theme.colorScheme.surface)
            .withValues(alpha: isDark ? 0.55 : 0.65);
    final radius = BorderRadius.circular(28.r);

    final navItems = [
      for (var i = 0; i < items.length; i++)
        GlassNavItemButton(
          item: items[i],
          isActive: i == currentIndex,
          onTap: () => onTap(i),
        ),
    ];
    return SafeArea(
      top: vertical,
      right: !vertical,
      child: Padding(
        padding: vertical
            ? EdgeInsets.fromLTRB(12.w, 12.h, 0, 12.h)
            : EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(
                  alpha: isDark ? 0.35 : 0.08,
                ),
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
                // Height follows the content (icon + label) so the bar
                // never overflows with large text scales or wide screens.
                padding: vertical
                    ? EdgeInsets.symmetric(vertical: 14.h, horizontal: 6.w)
                    : EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: glassColor,
                  borderRadius: radius,
                  border: Border.all(
                    color: onSurface.withValues(alpha: isDark ? 0.12 : 0.08),
                  ),
                ),
                child: vertical
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final item in navItems)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              child: item,
                            ),
                        ],
                      )
                    : Row(
                        children: [
                          for (final item in navItems) Expanded(child: item),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
