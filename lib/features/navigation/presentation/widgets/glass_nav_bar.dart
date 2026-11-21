import 'dart:ui';

import 'package:material_ui/material_ui.dart';

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/theme/app_colors.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';

/// A single destination shown in [GlassNavBar].
class GlassNavItem {
  const GlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Floating, frosted-glass bottom navigation bar.
///
/// Colors come from the active [ThemeData], so the bar follows light/dark
/// mode changes automatically. It hides itself while the software keyboard
/// is open and comes back when the keyboard closes.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<GlassNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const Duration _animationDuration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    // Only this widget depends on the keyboard inset, so opening the keyboard
    // does not rebuild the pages behind the bar.
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return AnimatedSwitcher(
      duration: _animationDuration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          alignment: Alignment.topCenter,
          child: child,
        ),
      ),
      child: isKeyboardOpen
          ? const SizedBox.shrink(key: ValueKey('nav-hidden'))
          : _GlassBar(
              key: const ValueKey('nav-visible'),
              items: items,
              currentIndex: currentIndex,
              onTap: onTap,
            ),
    );
  }
}

class _GlassBar extends StatelessWidget {
  const _GlassBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<GlassNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

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

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
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
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: glassColor,
                  borderRadius: radius,
                  border: Border.all(
                    color: onSurface.withValues(alpha: isDark ? 0.12 : 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _NavItem(
                          item: items[i],
                          isActive: i == currentIndex,
                          onTap: () => onTap(i),
                        ),
                      ),
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final GlassNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.primaryColor;
    final inactiveColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final color = isActive ? activeColor : inactiveColor;
    const duration = GlassNavBar._animationDuration;

    return Semantics(
      button: true,
      selected: isActive,
      label: item.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        highlightShape: BoxShape.rectangle,
        radius: 36.r,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 18.w : 12.w,
                vertical: 4.h,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withValues(alpha: 0.16)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: AnimatedSwitcher(
                duration: duration,
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  isActive ? item.activeIcon : item.icon,
                  key: ValueKey(isActive),
                  color: color,
                  size: 24.sp,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            AnimatedDefaultTextStyle(
              duration: duration,
              style: (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
                color: color,
                fontSize: AppTextSizes.sm,
                fontWeight: isActive
                    ? FontWeightHelper.bold
                    : FontWeightHelper.medium,
              ),
              child: Text(item.label, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}
