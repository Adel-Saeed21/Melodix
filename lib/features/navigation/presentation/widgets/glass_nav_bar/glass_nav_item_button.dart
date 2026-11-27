import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/features/navigation/presentation/widgets/glass_nav_bar.dart';

/// One destination: its icon (in the spot the bar's sliding pill moves
/// to) and label. The icon swaps to its filled form with a little pop.
class GlassNavItemButton extends StatelessWidget {
  const GlassNavItemButton({
    super.key,
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final GlassNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  /// The icon's spot, which the bar's pill ([GlassNavPill]) fills.
  static EdgeInsets iconPadding() =>
      EdgeInsets.symmetric(horizontal: 18.w, vertical: 3.h);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.primaryColor;
    final inactiveColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final color = isActive ? activeColor : inactiveColor;
    const duration = GlassNavBar.animationDuration;

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
            Padding(
              padding: iconPadding(),
              child: AnimatedScale(
                scale: isActive ? 1.1 : 1,
                duration: duration,
                curve: isActive ? Curves.easeOutBack : Curves.easeOut,
                child: AnimatedSwitcher(
                  duration: duration,
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    isActive ? item.activeIcon : item.icon,
                    key: ValueKey(isActive),
                    color: color,
                    size: 22.sp,
                  ),
                ),
              ),
            ),
            SizedBox(height: 2.h),
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

/// The tinted pill behind the active icon. The bar draws one and slides
/// it from tab to tab.
class GlassNavPill extends StatelessWidget {
  const GlassNavPill({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = GlassNavItemButton.iconPadding();
    return Container(
      width: 22.sp + padding.horizontal,
      height: 22.sp + padding.vertical,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16.r),
      ),
    );
  }
}
