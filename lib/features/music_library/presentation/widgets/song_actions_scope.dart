import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/features/music_library/presentation/logic/action_feedback.dart';
import 'package:melodix/features/music_library/presentation/logic/song_actions_cubit.dart';
import 'package:melodix/features/music_library/presentation/widgets/action_feedback_listener.dart';

/// Provides a [SongActionsCubit] for the song menus below it and shows each
/// action's feedback.
class SongActionsScope extends StatelessWidget {
  const SongActionsScope({super.key, required this.child, this.onAction});

  final Widget child;

  /// Called after every action, e.g. to reload a list that isn't live.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SongActionsCubit>(),
      child: ActionFeedbackListener<SongActionsCubit, ActionFeedback?>(
        feedbackOf: (feedback) => feedback,
        onFeedback: (_) => onAction?.call(),
        child: child,
      ),
    );
  }
}
