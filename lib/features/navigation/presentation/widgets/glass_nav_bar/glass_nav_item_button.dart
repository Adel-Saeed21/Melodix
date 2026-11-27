import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/features/navigation/presentation/widgets/glass_nav_bar.dart';

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
            AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 18.w : 12.w,
                vertical: 3.h,
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
                  size: 22.sp,
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
