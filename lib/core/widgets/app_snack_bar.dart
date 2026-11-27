import 'package:material_ui/material_ui.dart';

import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:melodix/core/widgets/app_snack_bar/snack_bar_card.dart';

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
          margin: EdgeInsetsDirectional.fromSTEB(20.w, 0, 20.w, 12.h),
          duration: !hasAction
              ? AppSnackBar.duration
              : _accessible
              ? AppSnackBar._accessibleActionDuration
              : AppSnackBar.durationWithAction,
          content: SnackBarCard(
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
