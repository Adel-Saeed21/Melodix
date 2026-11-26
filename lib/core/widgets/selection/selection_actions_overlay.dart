import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';
import 'package:melodix/core/service/spacing.dart';
import 'package:melodix/core/widgets/selection/selection_widgets.dart';

/// The actions for a selection (songs, videos), where the user chose in
/// Settings: a bar along the bottom, or a vertical bar down the right edge.
/// Slides in while selecting. Goes in the list's [Stack].
class SelectionActionsOverlay extends StatelessWidget {
  const SelectionActionsOverlay({
    super.key,
    required this.active,
    required this.enabled,
    required this.actions,
  });

  /// Selection mode is on.
  final bool active;

  /// False while nothing is selected.
  final bool enabled;
  final List<BulkAction> actions;

  static const Duration _animation = Duration(milliseconds: 220);

  /// Space to leave under the list so its last rows aren't hidden: only the
  /// bottom bar covers them.
  static double listBottomPadding(
    BuildContext context, {
    required bool active,
  }) {
    final bar =
        active &&
        UiPreferencesScope.of(context).selectionBar == SelectionBarStyle.bottom;
    return MediaQuery.paddingOf(context).bottom + (bar ? 96.h : 16.h);
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final side =
        UiPreferencesScope.of(context).selectionBar == SelectionBarStyle.side;

    Widget slideIn(Widget bar, Offset hidden) => IgnorePointer(
      ignoring: !active,
      child: AnimatedSlide(
        duration: _animation,
        curve: Curves.easeOutCubic,
        offset: active ? Offset.zero : hidden,
        child: AnimatedOpacity(
          duration: _animation,
          opacity: active ? 1 : 0,
          child: bar,
        ),
      ),
    );

    if (side) {
      return Positioned(
        top: 0,
        bottom: padding.bottom,
        right: padding.right + 10.w,
        child: Center(
          child: slideIn(
            SideActionBar(actions: actions, enabled: enabled),
            const Offset(1.6, 0),
          ),
        ),
      );
    }
    return Positioned(
      left: 16.w,
      right: 16.w,
      bottom: padding.bottom + 12.h,
      child: slideIn(
        BulkActionBar(actions: actions, enabled: enabled),
        const Offset(0, 1.6),
      ),
    );
  }
}

/// The actions stacked in a narrow bar (icon over a short label), for the
/// right edge: it covers no rows' content (their checks are on the left).
class SideActionBar extends StatelessWidget {
  const SideActionBar({
    super.key,
    required this.actions,
    required this.enabled,
  });

  final List<BulkAction> actions;
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
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final action in actions)
                Opacity(
                  opacity: enabled ? 1 : 0.4,
                  child: InkResponse(
                    onTap: enabled ? action.onTap : null,
                    radius: 30.r,
                    child: SizedBox(
                      width: 64.r,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
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
                              textAlign: TextAlign.center,
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
      ),
    );
  }
}
