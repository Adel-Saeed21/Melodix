import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/config/assets/app_strings.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/features/music_library/presentation/logic/song_actions_cubit.dart';

/// Provides a [SongActionsCubit] for the song menus below it and shows each
/// action's feedback as a SnackBar (with Undo after hiding songs).
class SongActionsScope extends StatelessWidget {
  const SongActionsScope({super.key, required this.child, this.onAction});

  final Widget child;

  /// Called after every action, e.g. to reload a list that isn't live.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SongActionsCubit>(),
      child: BlocListener<SongActionsCubit, SongActionFeedback?>(
        listener: (context, feedback) {
          onAction?.call();
          if (feedback == null) return;
          final cubit = context.read<SongActionsCubit>();
          final undoIds = feedback.undoHideIds;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(feedback.message),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
                action: undoIds.isEmpty
                    ? null
                    : SnackBarAction(
                        label: AppStrings.undo,
                        onPressed: () =>
                            cubit.unhideMany(undoIds, silent: true),
                      ),
              ),
            );
        },
        child: child,
      ),
    );
  }
}
