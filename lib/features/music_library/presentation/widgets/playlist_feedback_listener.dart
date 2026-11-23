import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/features/music_library/presentation/logic/playlists_cubit.dart';

/// Shows [PlaylistsCubit] action messages as SnackBars.
class PlaylistFeedbackListener extends StatelessWidget {
  const PlaylistFeedbackListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<PlaylistsCubit, PlaylistsState>(
      listenWhen: (previous, current) =>
          current.messageSequence != previous.messageSequence &&
          current.message != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.message!),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
      },
      child: child,
    );
  }
}
