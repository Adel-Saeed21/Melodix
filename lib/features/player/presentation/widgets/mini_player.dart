import 'package:melodix/core/l10n/l10n.dart';
import 'package:melodix/core/preferences/ui_preferences.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/core/widgets/app_snack_bar.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';
import 'package:melodix/features/player/presentation/utils/playback_error_text.dart';
import 'package:melodix/features/player/presentation/widgets/mini_player/mini_player_card.dart';
import 'package:melodix/features/player/presentation/widgets/mini_player/capsule_mini_player.dart';
import 'package:melodix/features/player/presentation/widgets/mini_player/minimal_mini_player.dart';

/// Compact player shown above the nav bar while a song is loaded. Hidden
/// when nothing is loaded and while the keyboard is open.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key, required this.onExpand});

  /// Opens the full player page.
  final VoidCallback onExpand;

  static const Duration _animation = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    // Own paint layer: the mini player's frequent updates (seek bar, time,
    // scrolling title) don't repaint the blurred nav bar or the page.
    return RepaintBoundary(
      child: BlocConsumer<PlayerCubit, NowPlaying>(
        listenWhen: (p, c) =>
            c.errorSequence != p.errorSequence && c.error != null,
        listener: (context, state) => AppSnackBar.show(
          context,
          playbackErrorText(state.error!, context.l10n),
          kind: AppSnackBarKind.error,
        ),
        builder: (context, state) {
          final visible = state.hasSong && !keyboardOpen;
          return AnimatedSwitcher(
            duration: _animation,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            ),
            child: visible
                ? switch (UiPreferencesScope.of(context).miniPlayer) {
                    MiniPlayerStyle.classic => MiniPlayerCard(
                      key: const ValueKey('mini-player'),
                      state: state,
                      onExpand: onExpand,
                    ),
                    MiniPlayerStyle.capsule => CapsuleMiniPlayer(
                      key: const ValueKey('mini-player-capsule'),
                      state: state,
                      onExpand: onExpand,
                    ),
                    MiniPlayerStyle.minimal => MinimalMiniPlayer(
                      key: const ValueKey('mini-player-minimal'),
                      state: state,
                      onExpand: onExpand,
                    ),
                  }
                : const SizedBox(
                    key: ValueKey('no-player'),
                    width: double.infinity,
                  ),
          );
        },
      ),
    );
  }
}
