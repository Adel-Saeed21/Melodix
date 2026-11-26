import 'dart:ui';

import 'package:material_ui/material_ui.dart';

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/config/theme/app_colors.dart';
import 'package:melodix/core/config/theme/app_text_sizes.dart';
import 'package:melodix/core/config/theme/font_weight_helper.dart';

enum AppSnackBarKind { success, error }

/// The app's short feedback message: a floating glass card in the same
/// style as the navigation bar, with an optional action (e.g. "Undo").
abstract final class AppSnackBar {
  /// How long a plain message stays.
  static const Duration duration = Duration(seconds: 2);

  /// With an action: long enough to reach the button.
  static const Duration durationWithAction = Duration(seconds: 3);

  /// With an action and a screen reader on: time to find the button.
  static const Duration _accessibleActionDuration = Duration(seconds: 10);

  /// Replaces the current message (if any) with [message].
  static void show(
    BuildContext context,
    String message, {
    AppSnackBarKind kind = AppSnackBarKind.success,
    String? actionLabel,
    VoidCallback? onAction,
  }) => AppSnackBarTarget.of(context)
      .show(message, kind: kind, actionLabel: actionLabel, onAction: onAction);
}

/// Where to show a message, taken from a [BuildContext] while it's still
/// there: for feedback that arrives after an `await`, when the widget that
/// asked (e.g. a row just removed from its list) may be gone.
class AppSnackBarTarget {
  AppSnackBarTarget.of(BuildContext context)
    : _messenger = ScaffoldMessenger.of(context),
      _accessible = MediaQuery.accessibleNavigationOf(context);

  final ScaffoldMessengerState _messenger;
  final bool _accessible;

  /// Like [AppSnackBar.show]; does nothing once the app's messenger is gone.
  void show(
    String message, {
    AppSnackBarKind kind = AppSnackBarKind.success,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!_messenger.mounted) return;
    final hasAction = actionLabel != null && onAction != null;
    final messenger = _messenger;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          // The card draws everything; the SnackBar is only the slot.
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
          duration: !hasAction
              ? AppSnackBar.duration
              : _accessible
              ? AppSnackBar._accessibleActionDuration
              : AppSnackBar.durationWithAction,
          content: _SnackBarCard(
            message: message,
            kind: kind,
            actionLabel: hasAction ? actionLabel : null,
            onAction: hasAction
                ? () {
                    messenger.hideCurrentSnackBar();
                    onAction();
                  }
                : null,
          ),
        ),
      );
  }
}

class _SnackBarCard extends StatelessWidget {
  const _SnackBarCard({
    required this.message,
    required this.kind,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final AppSnackBarKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final accent = switch (kind) {
      AppSnackBarKind.success => Theme.of(context).primaryColor,
      AppSnackBarKind.error => theme.colorScheme.error,
    };
    // The nav bar's glass, a little denser so text stays readable over
    // busy covers.
    final glass =
        (isDark
                ? AppColors.navigationBarDarkBackground
                : theme.colorScheme.surface)
            .withValues(alpha: isDark ? 0.85 : 0.9);
    final radius = BorderRadius.circular(20.r);
    final label = actionLabel;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: isDark ? 0.35 : 0.12),
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
            padding: EdgeInsets.fromLTRB(
              10.w,
              10.h,
              label == null ? 16.w : 8.w,
              10.h,
            ),
            decoration: BoxDecoration(
              color: glass,
              borderRadius: radius,
              border: Border.all(
                color: onSurface.withValues(alpha: isDark ? 0.12 : 0.08),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32.r,
                  height: 32.r,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    kind == AppSnackBarKind.success
                        ? Icons.check_rounded
                        : Icons.error_outline_rounded,
                    size: 18.r,
                    color: accent,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: onSurface,
                      fontSize: AppTextSizes.base,
                      fontWeight: FontWeightHelper.semiBold,
                    ),
                  ),
                ),
                if (label != null) ...[
                  SizedBox(width: 8.w),
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      backgroundColor: Theme.of(context).primaryColor
                          .withValues(alpha: 0.14),
                      shape: const StadiumBorder(),
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      minimumSize: Size(0, 36.h),
                      tapTargetSize: MaterialTapTargetSize.padded,
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: AppTextSizes.base,
                        fontWeight: FontWeightHelper.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
