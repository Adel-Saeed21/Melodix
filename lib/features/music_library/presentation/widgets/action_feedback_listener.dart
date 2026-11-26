import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/widgets/app_snack_bar.dart';
import 'package:melodix/features/music_library/presentation/logic/action_feedback.dart';

/// Shows each new [ActionFeedback] from the nearest [B] as an [AppSnackBar].
class ActionFeedbackListener<B extends StateStreamable<S>, S>
    extends StatelessWidget {
  const ActionFeedbackListener({
    super.key,
    required this.feedbackOf,
    required this.child,
    this.onFeedback,
  });

  /// The feedback held in [B]'s state.
  final ActionFeedback? Function(S state) feedbackOf;

  /// Called for every new message, e.g. to reload a list after an action.
  final ValueChanged<ActionFeedback>? onFeedback;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<B, S>(
      listenWhen: (previous, current) {
        final feedback = feedbackOf(current);
        return feedback != null && feedback != feedbackOf(previous);
      },
      listener: (context, state) {
        final feedback = feedbackOf(state)!;
        onFeedback?.call(feedback);
        AppSnackBar.show(
          context,
          feedback.message,
          kind: feedback.isError
              ? AppSnackBarKind.error
              : AppSnackBarKind.success,
        );
      },
      child: child,
    );
  }
}
