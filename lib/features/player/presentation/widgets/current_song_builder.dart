import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';

/// Builds with whether [songId] is the player's current song and whether it's
/// playing. Rebuilds only when that changes for this song (not on position
/// ticks, which [PlayerCubit] doesn't carry). Uses the [PlayerCubit] above
/// it in the tree; without one (e.g. an isolated widget test) it reports
/// "not current".
class CurrentSongBuilder extends StatelessWidget {
  const CurrentSongBuilder({
    super.key,
    required this.songId,
    required this.builder,
  });

  final int songId;
  final Widget Function(BuildContext context, bool isCurrent, bool isPlaying)
  builder;

  @override
  Widget build(BuildContext context) {
    final player = _playerAbove(context);
    if (player == null) return builder(context, false, false);
    return BlocSelector<PlayerCubit, NowPlaying, (bool, bool)>(
      bloc: player,
      selector: (state) {
        final isCurrent = state.currentSong?.id == songId;
        return (isCurrent, isCurrent && state.isPlaying);
      },
      builder: (context, mark) => builder(context, mark.$1, mark.$2),
    );
  }

  static PlayerCubit? _playerAbove(BuildContext context) {
    try {
      // (BlocProvider.of wraps "not found" in a FlutterError; read doesn't.)
      return context.read<PlayerCubit>();
    } on ProviderNotFoundException {
      return null;
    }
  }
}
