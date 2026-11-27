import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:melodix/features/music_library/presentation/widgets/song_actions_scope.dart';
import 'package:melodix/features/player/domain/entities/now_playing.dart';
import 'package:melodix/features/player/presentation/logic/player_cubit.dart';
import 'package:melodix/features/player/presentation/logic/playback_progress_cubit.dart';
import 'package:melodix/features/player/presentation/logic/player_lyrics_clock.dart';
import 'package:melodix/core/widgets/drag_to_dismiss.dart';
import 'package:melodix/core/config/dependency_injection/get_it.dart';
import 'package:melodix/features/lyrics/presentation/logic/lyrics_clock.dart';
import 'package:melodix/features/lyrics/presentation/logic/lyrics_cubit.dart';
import 'package:melodix/features/player/presentation/widgets/now_playing_backdrop.dart';
import 'package:melodix/features/player/presentation/widgets/now_playing/now_playing_body.dart';

/// Full player: large cover, song info, seek bar and all controls. Reads the
/// same [PlayerCubit] as the mini player, so both always match.
class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({super.key});

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> {
  bool _closing = false;

  /// Lyrics in place of the cover.
  bool _showLyrics = false;

  /// Leaves the page once if nothing is loaded anymore.
  void _closeOnce() {
    if (_closing) return;
    _closing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SongActionsScope(
      // Pull the page down (or tap ⌄) to go back to the mini player.
      child: DragToDismiss(
        onDismiss: () => Navigator.of(context).maybePop(),
        // What the lyrics follow: this player's position.
        child: RepositoryProvider<LyricsClock>(
          create: (context) => PlayerLyricsClock(
            progress: context.read<PlaybackProgressCubit>(),
            player: context.read<PlayerCubit>(),
          ),
          child: BlocProvider(
            // Made the first time lyrics are shown.
            create: (_) => getIt<LyricsCubit>(),
            child: Scaffold(
              body: BlocBuilder<PlayerCubit, NowPlaying>(
                builder: (context, state) {
                  final song = state.currentSong;
                  if (song == null) {
                    _closeOnce();
                    return const SizedBox.shrink();
                  }
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: NowPlayingBackdrop(songId: song.id),
                      ),
                      SafeArea(
                        child: NowPlayingBody(
                          state: state,
                          song: song,
                          showLyrics: _showLyrics,
                          onLyrics: () =>
                              setState(() => _showLyrics = !_showLyrics),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
