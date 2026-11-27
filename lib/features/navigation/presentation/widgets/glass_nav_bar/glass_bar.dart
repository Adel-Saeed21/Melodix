import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/theme/app_colors.dart';
import 'package:melodix/features/navigation/presentation/widgets/glass_nav_bar.dart';
import 'package:melodix/features/navigation/presentation/widgets/glass_nav_bar/glass_nav_item_button.dart';

/// The bar itself: frosted glass, the tabs along it (or down it, as a
/// rail), and the pill that slides to the one tapped.
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

  /// Space above and below each tab in the rail.
  static const double _railGap = 8;

  static const Duration _slide = Duration(milliseconds: 380);

  /// The pill in the active tab's slot: along the bar, or down the rail.
  Widget _slidingPill(BuildContext context) {
    final count = items.length;
    final at = count < 2 ? 0.0 : -1 + 2 * currentIndex / (count - 1);
    return AnimatedAlign(
      duration: _slide,
      curve: Curves.easeOutBack,
      alignment: vertical
          ? Alignment(0, at)
          // Along the reading direction (right to left in Arabic).
          : AlignmentDirectional(at, 0),
      child: FractionallySizedBox(
        widthFactor: vertical ? 1 : 1 / count,
        heightFactor: vertical ? 1 / count : 1,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: vertical ? _railGap.h : 0),
            child: const GlassNavPill(),
          ),
        ),
      ),
    );
  }

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
            ? EdgeInsetsDirectional.fromSTEB(12.w, 12.h, 0, 12.h)
            : EdgeInsetsDirectional.fromSTEB(20.w, 0, 20.w, 8.h),
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
                // Kept compact: it sits under the mini player.
                padding: vertical
                    ? EdgeInsets.symmetric(vertical: 14.h, horizontal: 6.w)
                    : EdgeInsets.symmetric(vertical: 6.h),
                decoration: BoxDecoration(
                  color: glassColor,
                  borderRadius: radius,
                  border: Border.all(
                    color: onSurface.withValues(alpha: isDark ? 0.12 : 0.08),
                  ),
                ),
                // The pill behind the active icon slides between the
                // tabs (each tab has an equal slot, so its place is
                // known from the index alone).
                child: Stack(
                  children: [
                    Positioned.fill(child: _slidingPill(context)),
                    if (vertical)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final item in navItems)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: _railGap.h,
                              ),
                              child: item,
                            ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          for (final item in navItems) Expanded(child: item),
                        ],
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
